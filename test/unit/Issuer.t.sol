// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Issuer} from "../../src/Issuer.sol";
import {BondMathLib} from "../../src/BondMathLib.sol";

contract IssuerTest is Test {
    Issuer public issuer;

    function setUp() public {
        address initialBasisRecipient = address(this);
        uint256 initialBasisSupply = 1e27;
        issuer = new Issuer(initialBasisRecipient, initialBasisSupply);
    }

    function test_maxDiscountRate_yearlyRate() public view {
        uint256 MAX_DISCOUNT_RATE_X1e18 = issuer.MAX_DISCOUNT_RATE_X1e18();
        uint256 yearlyDiscountRateX1e18 =
            BondMathLib.futureDiscountX1e18({discountRateX1e18: MAX_DISCOUNT_RATE_X1e18, timeToMaturity: 365 days});
        assertApproxEqRel(yearlyDiscountRateX1e18, 10e18, 1e12, "yearlyDiscountRateX1e18 should be 10");
    }

    function test_discountRate_yearlyRate() public {
        uint256 discountRateX1e18 = issuer.MAX_DISCOUNT_RATE_X1e18() * 12 / issuer.MAX_AUCTION_DURATION();
        uint256 yearlyDiscountRateX1e18 =
            BondMathLib.futureDiscountX1e18({discountRateX1e18: discountRateX1e18, timeToMaturity: 365 days});
        // TODO: check against desired value
        emit log_named_uint("yearlyDiscountRateX1e18 after one block", yearlyDiscountRateX1e18);

        discountRateX1e18 = issuer.MAX_DISCOUNT_RATE_X1e18() * 1 hours / issuer.MAX_AUCTION_DURATION();
        yearlyDiscountRateX1e18 =
            BondMathLib.futureDiscountX1e18({discountRateX1e18: discountRateX1e18, timeToMaturity: 365 days});
        // TODO: check against desired value
        emit log_named_uint("yearlyDiscountRateX1e18 after one hour", yearlyDiscountRateX1e18);
    }

    function test_initiateAuction() public {
        issuer.initiateAuction();
    }
}
