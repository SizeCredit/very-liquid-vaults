// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Auth, STRATEGIST_ROLE} from "@src/Auth.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";

contract SizeVault is BaseVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    EnumerableSet.AddressSet internal strategies;

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
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        Auth auth_,
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 firstDepositAmount_
    ) public virtual override initializer {
        super.initialize(auth_, asset_, name_, symbol_, firstDepositAmount_);
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setStrategies(address[] calldata strategies_) external whenNotPaused onlyAuth(STRATEGIST_ROLE) {
        uint256 length = strategies.length();
        for (uint256 i = 0; i < length; i++) {
            _removeStrategy(strategies.at(i));
        }
        for (uint256 i = 0; i < strategies_.length; i++) {
            _addStrategy(strategies_[i]);
        }
    }

    function addStrategy(address strategy) external whenNotPaused onlyAuth(STRATEGIST_ROLE) {
        _addStrategy(strategy);
    }

    function removeStrategy(address strategy) external whenNotPaused onlyAuth(STRATEGIST_ROLE) {
        _removeStrategy(strategy);
    }

    function rebalance(IStrategy strategyFrom, IStrategy strategyTo, uint256 amount)
        external
        whenNotPaused
        onlyAuth(STRATEGIST_ROLE)
    {
        if (!strategies.contains(address(strategyFrom))) {
            revert InvalidStrategy(address(strategyFrom));
        }
        if (!strategies.contains(address(strategyTo))) {
            revert InvalidStrategy(address(strategyTo));
        }

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

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getStrategies() external view returns (address[] memory) {
        return strategies.values();
    }

    function getStrategy(uint256 index) external view returns (address) {
        return strategies.at(index);
    }
}
