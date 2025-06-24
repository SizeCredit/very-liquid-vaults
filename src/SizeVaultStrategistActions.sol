// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {SizeVaultStorage} from "@src/SizeVaultStorage.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";

abstract contract SizeVaultStrategistActions is SizeVaultStorage, PausableUpgradeable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidStrategy(address strategy);

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setStrategies(address[] calldata strategies_) external whenNotPaused onlyRole(STRATEGIST_ROLE) {
        uint256 length = strategies.length();
        for (uint256 i = 0; i < length; i++) {
            _removeStrategy(strategies.at(i));
        }
        for (uint256 i = 0; i < strategies_.length; i++) {
            _addStrategy(strategies_[i]);
        }
    }

    function addStrategy(address strategy) external whenNotPaused onlyRole(STRATEGIST_ROLE) {
        _addStrategy(strategy);
    }

    function removeStrategy(address strategy) external whenNotPaused onlyRole(STRATEGIST_ROLE) {
        _removeStrategy(strategy);
    }

    function rebalance(IStrategy strategyFrom, IStrategy strategyTo, uint256 amount)
        external
        whenNotPaused
        onlyRole(STRATEGIST_ROLE)
    {
        require(strategies.contains(address(strategyFrom)), InvalidStrategy(address(strategyFrom)));
        require(strategies.contains(address(strategyTo)), InvalidStrategy(address(strategyTo)));

        strategyFrom.pullAssets(address(strategyTo), amount);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _addStrategy(address strategy) private {
        bool added = strategies.add(strategy);
        if (added) {
            emit StrategyAdded(strategy);
        }
    }

    function _removeStrategy(address strategy) private {
        bool removed = strategies.remove(strategy);
        if (removed) {
            emit StrategyRemoved(strategy);
        }
    }
}
