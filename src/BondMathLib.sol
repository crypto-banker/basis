// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

library BondMathLib {
    /// @notice returns present value of a future payout of `amountTokens` of a bond.
    /// @dev discountRateX1e18 must be expressed in terms of seconds to match the timescale.
    function presentFaceValue(uint256 amountTokens, uint256 discountRateX1e18, uint256 timeToMaturity)
        internal
        pure
        returns (uint256)
    {
        // par value / discount rate applied until expiry
        return (amountTokens * 1e18) / futureDiscountX1e18(discountRateX1e18, timeToMaturity);
    }

    /// @notice Inverse of `presentFaceValue` -- finds the discount rate when `price` is paid for a future payment of
    /// `amountTokens`, which will be paid `timeToMaturity` in the future.
    function discountRateX1e18OfPresentPrice(uint256 amountTokens, uint256 timeToMaturity, uint256 price)
        internal
        pure
        returns (int256)
    {
        // (discountRateX1e18 + 1e18) ^ timeToMaturity = (1e18 * amountTokens) / price
        // ln(discountRateX1e18 + 1e18) = ln((1e18 * amountTokens) / price) / timeToMaturity
        // discountRateX1e18 = e^[ln((1e18 * amountTokens) / price) / timeToMaturity] - 1e18
        int256 log = FixedPointMathLib.lnWad(int256(((1e18 * amountTokens) / price)));
        return FixedPointMathLib.expWad(log / int256(timeToMaturity)) - 1e18;
    }

    /// @notice Returns the rate at which to discount a future payout, based on the `discountRateX1e18`.
    /// @dev The `timeToMaturity` and `discountRateX1e18` must be in the same timescale. The implicit timescale is
    /// seconds, meaning that the implicit timescale for the discount rate is also seconds.
    function futureDiscountX1e18(uint256 discountRateX1e18, uint256 timeToMaturity) internal pure returns (uint256) {
        return uint256(FixedPointMathLib.powWad(int256(1e18 + discountRateX1e18), int256(timeToMaturity * 1e18)));
    }
}
