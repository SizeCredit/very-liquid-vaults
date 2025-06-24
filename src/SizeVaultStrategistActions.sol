// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {SizeVaultStorage} from "@src/SizeVaultStorage.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";
import {AddressDequeLibrary, AddressDeque} from "@src/libraries/AddressDequeLibrary.sol";

abstract contract SizeVaultStrategistActions is SizeVaultStorage, AccessControlUpgradeable {
    using AddressDequeLibrary for AddressDeque;

    function addStrategy(address strategy) external onlyRole(STRATEGIST_ROLE) {
        withdrawStrategyOrder.pushBack(strategy);
        depositStrategyOrder.pushBack(strategy);
    }

    function rebalance() external {
        // TODO: Implement rebalance
    }
}
