// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract IssuedToken is ERC20 {
    address public immutable ISSUER;

    error OnlyIssuer();

    constructor() ERC20("Basis Issued Token", "BIT") {
        ISSUER = msg.sender;
    }

    modifier onlyIssuer() {
        _checkIssuer();
        _;
    }

    function _checkIssuer() internal view {
        require(msg.sender == ISSUER, OnlyIssuer());
    }

    function mint(address account, uint256 value) external onlyIssuer {
        _mint(account, value);
    }

    function burn(address account, uint256 value) external onlyIssuer {
        _burn(account, value);
    }
}
