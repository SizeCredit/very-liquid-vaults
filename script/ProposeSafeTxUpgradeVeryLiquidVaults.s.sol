// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Safe} from "@safe-utils/src/Safe.sol";
import {Addresses} from "@script/Addresses.s.sol";
import {BaseScript} from "@script/BaseScript.s.sol";
import {VeryLiquidVault} from "@src/VeryLiquidVault.sol";
import {console} from "forge-std/console.sol";

contract ProposeSafeTxUpgradeVeryLiquidVaultsScript is BaseScript, Addresses {
    using Safe for *;

    Safe.Client internal safe;

    address signer;
    string derivationPath;

    function setUp() public override {
        super.setUp();
        signer = vm.envAddress("SIGNER");
        derivationPath = vm.envString("DERIVATION_PATH");
        safe.initialize(addresses[block.chainid][Contract.GovernanceMultisig]);
    }

    function run() public {
        vm.startBroadcast();

        address newImplementation = address(new VeryLiquidVault());
        console.log("New implementation", address(newImplementation));
        address[] memory veryLiquidVaults = block.chainid == 1
            ? getMainnetVeryLiquidVaults()
            : block.chainid == 8453 ? getBaseVeryLiquidVaults() : new address[](0);

        TimelockController timelockController =
            TimelockController(payable(addresses[block.chainid][Contract.TimelockController_DEFAULT_ADMIN_ROLE]));

        address[] memory multisigTargets = new address[](veryLiquidVaults.length);
        bytes[] memory multisigDatas = new bytes[](veryLiquidVaults.length);

        for (uint256 i = 0; i < veryLiquidVaults.length; i++) {
            address target = veryLiquidVaults[i];
            uint256 value = 0;
            bytes memory data = abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (newImplementation, ""));
            bytes32 predecessor = bytes32(0);
            bytes32 salt = keccak256(abi.encode(target, value, data, predecessor));
            uint256 delay = timelockController.getMinDelay();
            multisigTargets[i] = address(timelockController);
            multisigDatas[i] =
                abi.encodeCall(timelockController.schedule, (target, value, data, predecessor, salt, delay));
        }

        safe.proposeTransactions(multisigTargets, multisigDatas, signer, derivationPath);

        vm.stopBroadcast();
    }

    function getMainnetVeryLiquidVaults() public view returns (address[] memory ans) {
        ans = new address[](2);
        ans[0] = addresses[1][Contract.VeryLiquidVault_Core];
        ans[1] = addresses[1][Contract.VeryLiquidVault_Frontier];
        return ans;
    }

    function getBaseVeryLiquidVaults() public view returns (address[] memory ans) {
        ans = new address[](1);
        ans[0] = addresses[8453][Contract.VeryLiquidVault_Core];
        return ans;
    }
}
