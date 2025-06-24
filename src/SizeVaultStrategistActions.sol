// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {SizeVaultStorage} from "@src/SizeVaultStorage.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";
import {AddressDequeLibrary} from "@src/libraries/AddressDequeLibrary.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract SizeVaultStrategistActions is SizeVaultStorage, AccessControlUpgradeable {
    using AddressDequeLibrary for DoubleEndedQueue.Bytes32Deque;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidStrategy(address strategy);

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addStrategy(address strategy) external onlyRole(STRATEGIST_ROLE) {
        withdrawStrategyOrder.pushBack(strategy);
        depositStrategyOrder.pushBack(strategy);
    }

    function rebalance(IStrategy strategyFrom, IStrategy strategyTo, uint256 amount)
        external
        onlyRole(STRATEGIST_ROLE)
    {
        require(strategies.contains(address(strategyFrom)), InvalidStrategy(address(strategyFrom)));
        require(strategies.contains(address(strategyTo)), InvalidStrategy(address(strategyTo)));

        strategyFrom.pullAssets(address(strategyTo), amount);
    }
}
