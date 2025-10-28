// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Safe} from "@safe-utils/src/Safe.sol";
import {Addresses} from "@script/Addresses.s.sol";
import {BaseScript} from "@script/BaseScript.s.sol";
import {VeryLiquidVault} from "@src/VeryLiquidVault.sol";

import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {console} from "forge-std/console.sol";

contract ProposeSafeTxUpgradeToV0_1_3Script is BaseScript, Addresses {
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

        address newCashStrategyVaultImplementation = address(new CashStrategyVault());
        console.log("New CashStrategyVault implementation", address(newCashStrategyVaultImplementation));
        address newAaveStrategyVaultImplementation = address(new AaveStrategyVault());
        console.log("New AaveStrategyVault implementation", address(newAaveStrategyVaultImplementation));
        address newERC4626StrategyVaultImplementation = address(new ERC4626StrategyVault());
        console.log("New ERC4626StrategyVault implementation", address(newERC4626StrategyVaultImplementation));
        address newVeryLiquidVaultImplementation = address(new VeryLiquidVault());
        console.log("New VeryLiquidVault implementation", address(newVeryLiquidVaultImplementation));

        TimelockController timelockController =
            TimelockController(payable(addresses[block.chainid][Contract.TimelockController_DEFAULT_ADMIN_ROLE]));

        uint256 vaultsLength = veryLiquidVaults[block.chainid].length + cashStrategyVaults[block.chainid].length
            + aaveStrategyVaults[block.chainid].length + erc4626StrategyVaults[block.chainid].length;
        address[] memory multisigTargets = new address[](vaultsLength);
        bytes[] memory multisigDatas = new bytes[](vaultsLength);
        uint256 index = 0;

        index = _upgradeVaults(
            cashStrategyVaults[block.chainid],
            timelockController,
            multisigTargets,
            multisigDatas,
            newCashStrategyVaultImplementation,
            index
        );
        index = _upgradeVaults(
            aaveStrategyVaults[block.chainid],
            timelockController,
            multisigTargets,
            multisigDatas,
            newAaveStrategyVaultImplementation,
            index
        );
        index = _upgradeVaults(
            erc4626StrategyVaults[block.chainid],
            timelockController,
            multisigTargets,
            multisigDatas,
            newERC4626StrategyVaultImplementation,
            index
        );
        index = _upgradeVaults(
            veryLiquidVaults[block.chainid],
            timelockController,
            multisigTargets,
            multisigDatas,
            newVeryLiquidVaultImplementation,
            index
        );

        require(index == vaultsLength, "Index mismatch");

        safe.proposeTransactions(multisigTargets, multisigDatas, signer, derivationPath);
        vm.stopBroadcast();
    }

    function _upgradeVaults(
        address[] memory vaults,
        TimelockController timelockController,
        address[] memory targets,
        bytes[] memory datas,
        address implementation,
        uint256 index
    ) internal view returns (uint256 newIndex) {
        for (uint256 i = 0; i < vaults.length; i++) {
            targets[index] = address(timelockController);
            datas[index] = abi.encodeCall(
                timelockController.schedule,
                (
                    vaults[i],
                    0,
                    abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (implementation, "")),
                    bytes32(0),
                    keccak256(
                        abi.encode(
                            vaults[i],
                            0,
                            abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (implementation, "")),
                            bytes32(0)
                        )
                    ),
                    timelockController.getMinDelay()
                )
            );
            index++;
        }
        return index;
    }
}
