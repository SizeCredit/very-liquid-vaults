// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Auth, STRATEGIST_ROLE} from "@src/Auth.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SizeVault is BaseVault {
    using SafeERC20 for IERC20;
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
    error CannotDepositToStrategies(uint256 assets, uint256 shares, uint256 remainingAssets);
    error CannotWithdrawFromStrategies(uint256 assets, uint256 shares, uint256 missingAssets);

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
        uint256 firstDepositAmount,
        address[] memory strategies_
    ) public virtual initializer {
        for (uint256 i = 0; i < strategies_.length; i++) {
            _addStrategy(strategies_[i]);
        }

        super.initialize(auth_, asset_, name_, symbol_, firstDepositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view override returns (uint256) {
        uint256 length = strategies.length();
        uint256 max = 0;
        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(strategies.at(i));
            uint256 strategyMaxDeposit = strategy.maxDeposit(address(this));
            max = Math.saturatingAdd(max, strategyMaxDeposit);
        }
        return max;
    }

    function maxMint(address receiver) public view override returns (uint256) {
        uint256 maxDepositAmount = maxDeposit(receiver);
        return maxDepositAmount == type(uint256).max ? type(uint256).max : convertToShares(maxDepositAmount);
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        return Math.min(_convertToAssets(balanceOf(owner), Math.Rounding.Floor), _maxWithdraw());
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        return Math.min(balanceOf(owner), _convertToShares(_maxWithdraw(), Math.Rounding.Floor));
    }

    function totalAssets() public view virtual override returns (uint256) {
        uint256 length = strategies.length();
        uint256 total = 0;
        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(strategies.at(i));
            total += strategy.totalAssets();
        }
        return total;
    }

    /// @notice Deposit assets to strategies in order
    /// @dev Reverts if not all assets can be deposited to strategies
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        if (_isInitializing()) {
            // first deposit
            shares = assets;
        }

        super._deposit(caller, receiver, assets, shares);

        uint256 assetsToDeposit = assets;

        uint256 length = strategies.length();
        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(strategies.at(i));

            uint256 strategyMaxDeposit = strategy.maxDeposit(address(this));
            uint256 depositAmount = Math.min(assetsToDeposit, strategyMaxDeposit);
            IERC20(asset()).forceApprove(address(strategy), depositAmount);
            try strategy.deposit(depositAmount, address(this)) {
                assetsToDeposit -= depositAmount;
            } catch {
                IERC20(asset()).forceApprove(address(strategy), 0);
            }

            if (assetsToDeposit == 0) {
                break;
            }
        }
        if (assetsToDeposit > 0) {
            revert CannotDepositToStrategies(assets, shares, assetsToDeposit);
        }
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        uint256 assetsToWithdraw = assets;

        uint256 length = strategies.length();

        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(strategies.at(i));

            uint256 strategyMaxWithdraw = strategy.maxWithdraw(address(this));
            uint256 withdrawAmount = Math.min(assetsToWithdraw, strategyMaxWithdraw);
            try strategy.withdraw(withdrawAmount, address(this), address(this)) {
                assetsToWithdraw -= withdrawAmount;
            } catch {}

            if (assetsToWithdraw == 0) {
                break;
            }
        }
        if (assetsToWithdraw > 0) {
            revert CannotWithdrawFromStrategies(assets, shares, assetsToWithdraw);
        }

        super._withdraw(caller, receiver, owner, assets, shares);
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

    function _maxWithdraw() private view returns (uint256) {
        uint256 length = strategies.length();
        uint256 max = 0;
        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(strategies.at(i));
            uint256 strategyMaxWithdraw = strategy.maxWithdraw(address(this));
            max = Math.saturatingAdd(max, strategyMaxWithdraw);
        }
        return max;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function strategiesCount() public view returns (uint256) {
        return strategies.length();
    }

    function getStrategies() public view returns (address[] memory) {
        return strategies.values();
    }

    function getStrategy(uint256 index) public view returns (address) {
        return strategies.at(index);
    }
}
