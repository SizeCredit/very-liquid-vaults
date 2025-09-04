// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TimelockControllerEnumerable} from "@openzeppelin-community-contracts/contracts/governance/TimelockControllerEnumerable.sol";
import {Auth, DEFAULT_ADMIN_ROLE, VAULT_MANAGER_ROLE, STRATEGIST_ROLE, GUARDIAN_ROLE} from "@src/Auth.sol";
import {Script, console} from "forge-std/Script.sol";

contract ConfigureAuthRolesScript is Script {
    Auth auth;
    TimelockControllerEnumerable timelockController_DEFAULT_ADMIN_ROLE;
    TimelockControllerEnumerable timelockController_VAULT_MANAGER_ROLE;
    address[] guardians;
    address[] strategists;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        timelockController_DEFAULT_ADMIN_ROLE = TimelockControllerEnumerable(payable(vm.envAddress("TIMELOCK_DEFAULT_ADMIN_ROLE")));
        timelockController_VAULT_MANAGER_ROLE = TimelockControllerEnumerable(payable(vm.envAddress("TIMELOCK_VAULT_MANAGER_ROLE")));
        guardians = vm.envAddress("GUARDIANS", ",");
        strategists = vm.envAddress("STRATEGISTS", ",");
    }

    function run() public {
        vm.startBroadcast();

        // Check if deployer has DEFAULT_ADMIN_ROLE
        require(
            auth.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Deployer MUST have DEFAULT_ADMIN_ROLE to configure roles"
        );

        // Grant roles
        auth.grantRole(DEFAULT_ADMIN_ROLE, address(timelockController_DEFAULT_ADMIN_ROLE));
        auth.grantRole(VAULT_MANAGER_ROLE, address(timelockController_VAULT_MANAGER_ROLE));
        for (uint256 i = 0; i < guardians.length; i++) {
            auth.grantRole(GUARDIAN_ROLE, guardians[i]);
        }
        for (uint256 i = 0; i < strategists.length; i++) {
            auth.grantRole(STRATEGIST_ROLE, strategists[i]);
        }

        // Revoke DEFAULT_ADMIN_ROLE from deployer
        auth.revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Check if deployer does not have DEFAULT_ADMIN_ROLE after configuration
        require(
            !auth.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Deployer DOES NOT have DEFAULT_ADMIN_ROLE after configuration"
        );

        vm.stopBroadcast();
    }
}
