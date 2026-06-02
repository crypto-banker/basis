// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Math} from "openzeppelin/utils/math/Math.sol";
import {BondMathLib} from "./BondMathLib.sol";
import {IssuedToken} from "./IssuedToken.sol";

/// @notice On construction, deploys the basis token. Issues and sells endogenous bonds for the basis token at
/// expirations up to `MAX_TIME_TO_MATURITY` into the future. Bonds are sold via Dutch Auction, which linearly increases
/// the discount rate for bonds from `0` up to a maximum of `MAX_DISCOUNT_RATE_X1e18` over the `MAX_AUCTION_DURATION`.
/// Anyone can initiate an auction via the `initiateAuction()` function as long as less than half of all extant basis
/// tokens (including those "in bonds") are currently in bonds and no auction is currently ongoing. While an auction is
/// ongoing, anyone may purchase a bond at any valid expiry, at the `currentAuctionDiscountX1e18()`. Auctions support
/// partial fills but continue until all tokens are sold, with the discount rate remaining at `MAX_DISCOUNT_RATE_X1e18`
/// once the time since `auctionStartTimestamp()` exceeds `MAX_AUCTION_DURATION`.
contract Issuer {
    struct AuctionStorage {
        uint256 startTimestamp;
        uint256 remainingTokens;
    }

    uint256 public constant MIN_ISSUANCE = 1000e18;
    uint256 public constant MAX_TIME_TO_MATURITY = 4 * 365 days;
    // (1e18 + MAX_DISCOUNT_RATE_X1e18)^(365 days) ~= 10e18
    uint256 public constant MAX_DISCOUNT_RATE_X1e18 = 73014496989;
    uint256 public constant MAX_AUCTION_DURATION = 7 days;

    IssuedToken public immutable basis;

    uint256 public totalBondTokens;

    mapping(uint256 expiry => IssuedToken bondContract) public bondByExpiry;

    AuctionStorage internal _auctionStorage;

    event BondContractDeployed(uint256 expiry, address bond);
    event AuctionInitiated(uint256 amountTokens);
    event AuctionConcluded();

    error BondNotExpired();
    error BondDoesNotExist();
    error AuctionAlreadyOngoing();
    error AuctionNotOngoing();
    error ExpiryCannotBeInPast();
    error TimeToMaturityExceedsMax();
    error PurchaseExceedsRemainingTokens();

    constructor(address initialBasisRecipient, uint256 initialBasisSupply) {
        basis = new IssuedToken();
        basis.mint(initialBasisRecipient, initialBasisSupply);
    }

    // NON-STATE-MODIFYING FUNCTIONS
    function auctionStartTimestamp() public view returns (uint256) {
        return _auctionStorage.startTimestamp;
    }

    function remainingTokensInAuction() public view returns (uint256) {
        return _auctionStorage.remainingTokens;
    }

    function auctionIsOngoing() public view returns (bool) {
        return auctionStartTimestamp() != 0;
    }

    function currentAuctionDiscountX1e18() public view returns (uint256) {
        if (!auctionIsOngoing()) {
            return 0;
        } else {
            uint256 elapsedTime = Math.min(auctionStartTimestamp() - block.timestamp, MAX_AUCTION_DURATION);
            return MAX_DISCOUNT_RATE_X1e18 * elapsedTime / MAX_AUCTION_DURATION;
        }
    }

    function bondExistsForExpiry(uint256 expiry) public view returns (bool) {
        return _bondExists(bondByExpiry[expiry]);
    }

    function predictBondAddress(uint256 expiry) external view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(this), bytes32(expiry), keccak256(type(IssuedToken).creationCode)
                        )
                    )
                )
            )
        );
    }

    function _bondExists(IssuedToken bond) internal pure returns (bool) {
        return address(bond) != address(0);
    }

    // EXTERNAL STATE-MODIFYING FUNCTIONS
    /// @notice Redeems `amount` of `bondByExpiry[expiry]` from the caller's account
    function redeemBond(uint256 expiry, uint256 amount) public {
        require(expiry <= block.timestamp, BondNotExpired());
        IssuedToken bond = bondByExpiry[expiry];
        require(_bondExists(bond), BondDoesNotExist());
        totalBondTokens -= amount;
        // TODO: ability to redeem bonds from different addresses
        bond.burn(msg.sender, amount);
        basis.mint(msg.sender, amount);
    }

    /// @notice Convenience function for redeeming all of the caller's current balance of `bondByExpiry[expiry]`
    function redeemBond(uint256 expiry) external {
        uint256 amount = bondByExpiry[expiry].balanceOf(msg.sender);
        redeemBond(expiry, amount);
    }

    function initiateAuction() external {
        require(!auctionIsOngoing(), AuctionAlreadyOngoing());
        uint256 basisSupply = basis.totalSupply();
        uint256 _totalBondTokens = totalBondTokens;
        require(basisSupply >= _totalBondTokens, "at least half of all extant basis is currently in bonds already");
        uint256 amountToAuction = Math.max(MIN_ISSUANCE, (basisSupply - _totalBondTokens) / 100);
        emit AuctionInitiated(amountToAuction);
        _auctionStorage.remainingTokens = amountToAuction;
        _auctionStorage.startTimestamp = block.timestamp;
    }

    function purchaseBond(uint256 expiry, uint256 amount) public {
        require(expiry >= block.timestamp, ExpiryCannotBeInPast());
        require(expiry - block.timestamp <= MAX_TIME_TO_MATURITY, TimeToMaturityExceedsMax());
        require(amount <= remainingTokensInAuction(), PurchaseExceedsRemainingTokens());
        require(auctionIsOngoing(), AuctionNotOngoing());
        uint256 _currentAuctionDiscountX1e18 = currentAuctionDiscountX1e18();
        uint256 price = BondMathLib.presentFaceValue({
            amountTokens: amount,
            discountRateX1e18: _currentAuctionDiscountX1e18,
            timeToMaturity: expiry - block.timestamp
        });
        _auctionStorage.remainingTokens -= amount;
        if (_auctionStorage.remainingTokens == 0) {
            _auctionStorage.startTimestamp = 0;
            emit AuctionConcluded();
        }
        totalBondTokens += amount;
        IssuedToken bond = _deployBond(expiry);
        basis.burn(msg.sender, price);
        bond.mint(msg.sender, amount);
    }

    function purchaseBond(uint256 expiry) external {
        purchaseBond(expiry, remainingTokensInAuction());
    }

    // INTERNAL STATE-MODIFYING FUNCTIONS
    function _deployBond(uint256 expiry) internal returns (IssuedToken) {
        IssuedToken bond = bondByExpiry[expiry];
        if (!_bondExists(bond)) {
            bond = new IssuedToken{salt: bytes32(expiry)}();
            bondByExpiry[expiry] = bond;
            emit BondContractDeployed(expiry, address(bond));
            return bond;
        } else {
            return bond;
        }
    }
}
