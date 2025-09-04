// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/Auth.sol";
import {Script, console} from "forge-std/Script.sol";

contract TimelockControllerScript is Script {
    address adminMultisig;
    address vaultManagerMultisig;
    address[] guardians;
    address[] strategists;

    function setUp() public {
        adminMultisig = vm.envAddress("ADMIN_MULTISIG");
        vaultManagerMultisig = vm.envAddress("VAULT_MANAGER_MULTISIG");
        guardians = vm.envAddress("GUARDIANS", ",");
        strategists = vm.envAddress("STRATEGISTS", ",");
    }

    function run() public {
        vm.startBroadcast();

        address[] memory adminTimelockAddresses = new address[](1);
        adminTimelockAddresses[0] = adminMultisig;
        TimelockController timelockController_DEFAULT_ADMIN_ROLE =
            new TimelockController(7 days, adminTimelockAddresses, adminTimelockAddresses, msg.sender);
        console.log("TimelockController (DEFAULT_ADMIN_ROLE)", address(timelockController_DEFAULT_ADMIN_ROLE));
        for (uint256 i = 0; i < guardians.length; i++) {
            timelockController_DEFAULT_ADMIN_ROLE.grantRole(
                timelockController_DEFAULT_ADMIN_ROLE.CANCELLER_ROLE(), guardians[i]
            );
        }
        timelockController_DEFAULT_ADMIN_ROLE.renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        address[] memory vaultManagerAddresses = new address[](1);
        vaultManagerAddresses[0] = vaultManagerMultisig;
        TimelockController timelockController_VAULT_MANAGER_ROLE =
            new TimelockController(1 days, vaultManagerAddresses, vaultManagerAddresses, msg.sender);
        console.log("TimelockController (VAULT_MANAGER_ROLE)", address(timelockController_VAULT_MANAGER_ROLE));
        for (uint256 i = 0; i < guardians.length; i++) {
            timelockController_VAULT_MANAGER_ROLE.grantRole(
                timelockController_VAULT_MANAGER_ROLE.CANCELLER_ROLE(), guardians[i]
            );
        }
        timelockController_VAULT_MANAGER_ROLE.renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        vm.stopBroadcast();
    }

    function deploy(uint256 minDelay_, address[] memory proposers_, address[] memory executors_, address admin_)
        public
        returns (TimelockController)
    {
        return new TimelockController(minDelay_, proposers_, executors_, admin_);
    }
}
