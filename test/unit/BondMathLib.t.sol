// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BondMathLib} from "../../src/BondMathLib.sol";

contract BondMathLibTest is Test {
    // 229197000000 = ln(1.02)/86400*e18
    uint256 constant TWO_PERCENT_DAILY_RATE = 229197000000;

    function setUp() public {}

    function test_futureDiscountX1e18_zeroDiscountRate() public pure {
        uint256 futureDiscountX1e18 = BondMathLib.futureDiscountX1e18({discountRateX1e18: 0, timeToMaturity: 1 days});
        assertEq(futureDiscountX1e18, 1e18, "zero discount rate should result in zero discount");
    }

    function test_futureDiscountX1e18_zeroTimeToPayout() public pure {
        uint256 futureDiscountX1e18 = BondMathLib.futureDiscountX1e18({discountRateX1e18: 1e18, timeToMaturity: 0});
        assertEq(futureDiscountX1e18, 1e18, "zero time to payout should result in zero discount");
    }

    function test_futureDiscountX1e18_twoPercentDailyRate() public pure {
        uint256 futureDiscountX1e18 =
            BondMathLib.futureDiscountX1e18({discountRateX1e18: TWO_PERCENT_DAILY_RATE, timeToMaturity: 1 days});
        assertApproxEqRel(futureDiscountX1e18, 1.02e18, 1e12, "future discount should be two percent");
    }

    function test_presentFaceValue() public pure {
        uint256 amountTokens = 1e18;
        uint256 presentFaceValue = BondMathLib.presentFaceValue({
            amountTokens: amountTokens, discountRateX1e18: TWO_PERCENT_DAILY_RATE, timeToMaturity: 1 days
        });
        uint256 expectedFaceValue = amountTokens * 1e18 / 1.02e18;
        assertApproxEqRel(
            presentFaceValue, expectedFaceValue, 1e12, "presentFaceValue not close enough to expectedFaceValue"
        );
    }

    function test_discountRateX1e18OfPresentPrice() public pure {
        uint256 amountTokens = 1e18;
        int256 discountRateX1e18OfPresentPrice = BondMathLib.discountRateX1e18OfPresentPrice({
            amountTokens: 1e18, timeToMaturity: 1 days, price: amountTokens * 1e18 / 1.02e18
        });
        uint256 expectedDiscountRate = TWO_PERCENT_DAILY_RATE;
        assertApproxEqRel(
            uint256(discountRateX1e18OfPresentPrice),
            expectedDiscountRate,
            1e12,
            "discountRateX1e18OfPresentPrice not close enough to expectedDiscountRate"
        );
    }
}
