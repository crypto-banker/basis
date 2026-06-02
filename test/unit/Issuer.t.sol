// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Issuer} from "../../src/Issuer.sol";

contract IssuerTest is Test {
    Issuer public issuer;

    function setUp() public {
        address initialBasisRecipient = address(this);
        uint256 initialBasisSupply = 1e27;
        issuer = new Issuer(initialBasisRecipient, initialBasisSupply);
    }

    function test_initiateAuction() public {
        issuer.initiateAuction();
    }
}
