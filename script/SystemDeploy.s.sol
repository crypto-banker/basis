// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {Issuer} from "../src/Issuer.sol";
import {IssuedToken} from "../src/IssuedToken.sol";

contract SystemDeploy is Script, Test {
    Issuer public issuer;

    function run() public {
        // forge-lint: disable-next-line(unsafe-cheatcode)
        string memory json = vm.readFile(_configFilePath("config.json"));
        uint256 configChainId = stdJson.readUint(json, ".chainid");
        require(configChainId == block.chainid, "incorrect config for this chainid");

        address initialBasisRecipient = stdJson.readAddress(json, ".initialBasisRecipient");
        uint256 initialBasisSupply = stdJson.readUint(json, ".initialBasisSupply");

        assertNotEq(initialBasisRecipient, address(0), "initialBasisRecipient unset");
        assertNotEq(initialBasisSupply, 0, "initialBasisSupply unset");

        vm.startBroadcast();

        issuer = new Issuer(initialBasisRecipient, initialBasisSupply);

        vm.stopBroadcast();

        // Serialize deployment info
        string memory systemDeployment = "System Deployment";
        vm.serializeAddress(systemDeployment, "issuer", address(issuer));
        vm.serializeAddress(systemDeployment, "basis", address(issuer.basis()));
        vm.serializeAddress(systemDeployment, "initialBasisRecipient", initialBasisRecipient);
        vm.serializeUint(systemDeployment, "initialBasisSupply", initialBasisSupply);
        string memory systemDeploymentOutput = vm.serializeAddress(systemDeployment, "deployer", msg.sender);

        vm.writeJson(systemDeploymentOutput, _deploymentFilePath("system_deploy.json"));
    }

    function _configFilePath(string memory fileName) internal view returns (string memory) {
        return string.concat("script/configs/", _networkConfigDirectory(), "/", fileName);
    }

    function _deploymentFilePath(string memory fileName) internal view returns (string memory) {
        return string.concat("script/deployments/", _networkConfigDirectory(), "/", fileName);
    }

    function _networkConfigDirectory() internal view returns (string memory) {
        if (block.chainid == 1) {
            return "mainnet";
        } else if (block.chainid == 8453) {
            return "base";
        } else if (block.chainid == 31337) {
            return "anvil";
        } else {
            revert("chainid not supported");
        }
    }
}
