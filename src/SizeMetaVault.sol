// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {PerformanceVault} from "@src/PerformanceVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Auth, STRATEGIST_ROLE, DEFAULT_ADMIN_ROLE, VAULT_MANAGER_ROLE} from "@src/Auth.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SizeMetaVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Meta vault that distributes assets across multiple strategies
/// @dev Extends PerformanceVault to manage multiple strategy vaults for asset allocation. By default, the performance fee is 0.
contract SizeMetaVault is PerformanceVault {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_STRATEGIES = 10;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IBaseVault[] public strategies;
    uint256 public defaultMaxSlippagePercent;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event StrategyAdded(address indexed strategy);
    event StrategyRemoved(address indexed strategy);
    event Rebalance(address indexed strategyFrom, address indexed strategyTo, uint256 rebalancedAmount);
    event DefaultMaxSlippagePercentSet(uint256 oldDefaultMaxSlippagePercent, uint256 newDefaultMaxSlippagePercent);

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidStrategy(address strategy);
    error CannotDepositToStrategies(uint256 assets, uint256 shares, uint256 remainingAssets);
    error CannotWithdrawFromStrategies(uint256 assets, uint256 shares, uint256 missingAssets);
    error TransferredAmountLessThanMin(
        uint256 assetsBefore, uint256 assetsAfter, uint256 slippage, uint256 amount, uint256 maxSlippagePercent
    );
    error MaxStrategiesExceeded(uint256 strategiesCount, uint256 maxStrategies);
    error ArrayLengthMismatch(uint256 expectedLength, uint256 actualLength);
    error InvalidMaxSlippagePercent(uint256 maxSlippagePercent);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the SizeMetaVault with strategies
    /// @dev Adds all provided strategies and calls parent initialization
    function initialize(
        Auth auth_,
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        address fundingAccount,
        uint256 firstDepositAmount,
        IBaseVault[] memory strategies_
    ) public virtual initializer {
        __PerformanceVault_init(auth_.getRoleMember(DEFAULT_ADMIN_ROLE, 0), 0);

        for (uint256 i = 0; i < strategies_.length; i++) {
            _addStrategy(strategies_[i], address(asset_), address(auth_));
        }
        _setDefaultMaxSlippagePercent(0.01e18);

        super.initialize(auth_, asset_, name_, symbol_, fundingAccount, firstDepositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum amount that can be deposited
    function maxDeposit(address receiver) public view override(BaseVault) returns (uint256) {
        return Math.min(_maxDeposit(), super.maxDeposit(receiver));
    }

    /// @notice Returns the maximum number of shares that can be minted
    function maxMint(address receiver) public view override(BaseVault) returns (uint256) {
        return Math.min(_maxMint(), super.maxMint(receiver));
    }

    /// @notice Returns the maximum amount that can be withdrawn by an owner
    function maxWithdraw(address owner) public view override(BaseVault) returns (uint256) {
        return Math.min(_maxWithdraw(), super.maxWithdraw(owner));
    }

    /// @notice Returns the maximum number of shares that can be redeemed
    function maxRedeem(address owner) public view override(BaseVault) returns (uint256) {
        return Math.min(_maxRedeem(), super.maxRedeem(owner));
    }

    /// @notice Returns the total assets managed by the vault
    // slither-disable-next-line calls-loop
    function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256 total) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            total += _strategyAssets(strategies[i]);
        }
    }

    /// @notice Deposits assets to strategies in order
    /// @dev Tries to deposit to strategies sequentially, reverts if not all assets can be deposited
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        if (_isInitializing()) {
            // first deposit
            shares = assets;
        }

        super._deposit(caller, receiver, assets, shares);

        _depositToStrategies(assets, shares);
    }

    /// @notice Withdraws assets from strategies in order
    /// @dev Tries to withdraw from strategies sequentially, reverts if not enough assets available
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        _withdrawFromStrategies(assets, shares);

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the performance fee percent
    function setPerformanceFeePercent(uint256 performanceFeePercent_) external notPaused onlyAuth(DEFAULT_ADMIN_ROLE) {
        _setPerformanceFeePercent(performanceFeePercent_);
    }

    /// @notice Sets the fee recipient
    function setFeeRecipient(address feeRecipient_) external notPaused onlyAuth(DEFAULT_ADMIN_ROLE) {
        _setFeeRecipient(feeRecipient_);
    }

    /*//////////////////////////////////////////////////////////////
                              VAULT MANAGER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds new strategies to the vault
    /// @dev Only callable by addresses with VAULT_MANAGER_ROLE
    function addStrategies(IBaseVault[] calldata strategies_) external notPaused onlyAuth(VAULT_MANAGER_ROLE) {
        for (uint256 i = 0; i < strategies_.length; i++) {
            _addStrategy(strategies_[i], asset(), address(auth));
        }
    }

    /// @notice Removes strategies from the vault and transfers all assets, if any, to another strategy
    /// @dev Only callable by addresses with VAULT_MANAGER_ROLE
    // slither-disable-next-line calls-loop
    function removeStrategies(
        IBaseVault[] calldata strategiesToRemove,
        IBaseVault strategyToReceiveAssets,
        uint256 maxSlippagePercent
    ) external nonReentrant notPaused onlyAuth(VAULT_MANAGER_ROLE) {
        for (uint256 i = 0; i < strategiesToRemove.length; i++) {
            IBaseVault strategyToRemove = strategiesToRemove[i];
            if (!isStrategy(strategyToRemove)) {
                revert InvalidStrategy(address(strategyToRemove));
            }
            uint256 strategyAssets = _strategyAssets(strategyToRemove);
            if (strategyAssets > 0) {
                _rebalance(strategyToRemove, strategyToReceiveAssets, strategyAssets, maxSlippagePercent);
            }
            _removeStrategy(strategyToRemove);
        }
    }

    /// @notice Sets the default max slippage percent
    /// @dev Only callable by addresses with VAULT_MANAGER_ROLE
    function setDefaultMaxSlippagePercent(uint256 defaultMaxSlippagePercent_)
        external
        notPaused
        onlyAuth(VAULT_MANAGER_ROLE)
    {
        _setDefaultMaxSlippagePercent(defaultMaxSlippagePercent_);
    }

    /*//////////////////////////////////////////////////////////////
                              STRATEGST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reorders the strategies
    /// @dev Verifies that the new strategies order is valid and that there are no duplicates
    /// @dev Clears current strategies and adds them in the new order
    function reorderStrategies(IBaseVault[] calldata newStrategiesOrder) external notPaused onlyAuth(STRATEGIST_ROLE) {
        if (strategies.length != newStrategiesOrder.length) {
            revert ArrayLengthMismatch(strategies.length, newStrategiesOrder.length);
        }

        for (uint256 i = 0; i < newStrategiesOrder.length; i++) {
            if (!isStrategy(newStrategiesOrder[i])) {
                revert InvalidStrategy(address(newStrategiesOrder[i]));
            }
            for (uint256 j = i + 1; j < newStrategiesOrder.length; j++) {
                if (newStrategiesOrder[i] == newStrategiesOrder[j]) {
                    revert InvalidStrategy(address(newStrategiesOrder[i]));
                }
            }
        }

        IBaseVault[] memory oldStrategiesOrder = strategies;
        for (uint256 i = 0; i < oldStrategiesOrder.length; i++) {
            _removeStrategy(oldStrategiesOrder[i]);
        }
        for (uint256 i = 0; i < newStrategiesOrder.length; i++) {
            _addStrategy(newStrategiesOrder[i], asset(), address(auth));
        }
    }

    /// @notice Rebalances assets between two strategies
    /// @dev Transfers assets from one strategy to another
    function rebalance(IBaseVault strategyFrom, IBaseVault strategyTo, uint256 amount, uint256 maxSlippagePercent)
        external
        nonReentrant
        notPaused
        onlyAuth(STRATEGIST_ROLE)
    {
        _rebalance(strategyFrom, strategyTo, amount, maxSlippagePercent);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal function to add a strategy
    /// @dev Strategy configuration is assumed to be correct (non-malicious, no circular dependencies, etc.)
    // slither-disable-next-line calls-loop
    function _addStrategy(IBaseVault strategy_, address asset_, address auth_) private {
        if (address(strategy_) == address(0)) {
            revert NullAddress();
        }
        if (isStrategy(strategy_)) {
            revert InvalidStrategy(address(strategy_));
        }
        if (strategy_.asset() != asset_ || address(strategy_.auth()) != auth_) {
            revert InvalidStrategy(address(strategy_));
        }
        strategies.push(strategy_);
        emit StrategyAdded(address(strategy_));
        if (strategies.length > MAX_STRATEGIES) {
            revert MaxStrategiesExceeded(strategies.length, MAX_STRATEGIES);
        }
    }

    /// @notice Internal function to remove a strategy
    /// @dev No NullAddress check is needed because only whitelisted strategies can be removed, and it is checked in _addStrategy
    /// @dev Removes the strategy in-place to keep the order
    function _removeStrategy(IBaseVault strategy) private {
        bool removed = false;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategy) {
                for (uint256 j = i; j < strategies.length - 1; j++) {
                    strategies[j] = strategies[j + 1];
                }
                strategies.pop();
                emit StrategyRemoved(address(strategy));
                removed = true;
                break;
            }
        }
        if (!removed) {
            revert InvalidStrategy(address(strategy));
        }
    }

    /// @notice Internal function to set the default max slippage percent
    function _setDefaultMaxSlippagePercent(uint256 defaultMaxSlippagePercent_) private {
        if (defaultMaxSlippagePercent_ > PERCENT) {
            revert InvalidMaxSlippagePercent(defaultMaxSlippagePercent_);
        }
        uint256 oldDefaultMaxSlippagePercent = defaultMaxSlippagePercent;
        defaultMaxSlippagePercent = defaultMaxSlippagePercent_;
        emit DefaultMaxSlippagePercentSet(oldDefaultMaxSlippagePercent, defaultMaxSlippagePercent_);
    }

    /// @notice Internal function to calculate maximum depositable amount in all strategies
    // slither-disable-next-line calls-loop
    function _maxDeposit() private view returns (uint256 maxAssets) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            IBaseVault strategy = strategies[i];
            uint256 strategyMaxDeposit = strategy.maxDeposit(address(this));
            maxAssets = Math.saturatingAdd(maxAssets, strategyMaxDeposit);
        }
    }

    /// @notice Internal function to calculate maximum mintable amount from all strategies
    // slither-disable-next-line calls-loop
    function _maxMint() private view returns (uint256 maxShares) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 strategyMaxMint = strategies[i].maxMint(address(this));
            maxShares = Math.saturatingAdd(maxShares, strategyMaxMint);
        }
    }

    /// @notice Internal function to calculate maximum withdrawable amount from all strategies
    // slither-disable-next-line calls-loop
    function _maxWithdraw() private view returns (uint256 maxAssets) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 strategyMaxWithdraw = strategies[i].maxWithdraw(address(this));
            maxAssets = Math.saturatingAdd(maxAssets, strategyMaxWithdraw);
        }
    }

    /// @notice Internal function to calculate maximum redeemable amount from all strategies
    // slither-disable-next-line calls-loop
    function _maxRedeem() private view returns (uint256 maxShares) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 strategyMaxRedeem = strategies[i].maxRedeem(address(this));
            maxShares = Math.saturatingAdd(maxShares, strategyMaxRedeem);
        }
    }

    /// @notice Internal function to deposit assets to strategies
    // slither-disable-next-line calls-loop
    function _depositToStrategies(uint256 assets, uint256 shares) private {
        uint256 assetsToDeposit = assets;

        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            IBaseVault strategy = strategies[i];
            uint256 strategyMaxDeposit = strategy.maxDeposit(address(this));
            uint256 depositAmount = Math.min(assetsToDeposit, strategyMaxDeposit);

            if (depositAmount > 0) {
                IERC20(asset()).forceApprove(address(strategy), depositAmount);
                // slither-disable-next-line unused-return
                try strategy.deposit(depositAmount, address(this)) {
                    assetsToDeposit -= depositAmount;
                } catch {
                    IERC20(asset()).forceApprove(address(strategy), 0);
                }
            }
        }
        if (assetsToDeposit > 0) {
            revert CannotDepositToStrategies(assets, shares, assetsToDeposit);
        }
    }

    /// @notice Internal function to withdraw assets from strategies
    // slither-disable-next-line calls-loop
    function _withdrawFromStrategies(uint256 assets, uint256 shares) private {
        uint256 assetsToWithdraw = assets;

        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            IBaseVault strategy = strategies[i];

            uint256 strategyMaxWithdraw = strategy.maxWithdraw(address(this));
            uint256 withdrawAmount = Math.min(assetsToWithdraw, strategyMaxWithdraw);

            if (withdrawAmount > 0) {
                uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
                // slither-disable-next-line unused-return
                try strategy.withdraw(withdrawAmount, address(this), address(this)) {
                    uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
                    assetsToWithdraw -= (balanceAfter - balanceBefore);
                } catch {}
            }
        }
        if (assetsToWithdraw > 0) {
            revert CannotWithdrawFromStrategies(assets, shares, assetsToWithdraw);
        }
    }

    /// @notice Internal function to rebalance assets between two strategies
    /// @dev If before - after > maxSlippagePercent * amount, the _rebalance operation reverts
    function _rebalance(IBaseVault strategyFrom, IBaseVault strategyTo, uint256 amount, uint256 maxSlippagePercent)
        private
    {
        maxSlippagePercent = Math.min(maxSlippagePercent, defaultMaxSlippagePercent);

        if (!isStrategy(strategyFrom)) {
            revert InvalidStrategy(address(strategyFrom));
        }
        if (!isStrategy(strategyTo)) {
            revert InvalidStrategy(address(strategyTo));
        }
        if (strategyFrom == strategyTo) {
            revert InvalidStrategy(address(strategyTo));
        }
        if (amount == 0) {
            revert NullAmount();
        }
        if (maxSlippagePercent > PERCENT) {
            revert InvalidMaxSlippagePercent(maxSlippagePercent);
        }

        uint256 assetsBefore = _strategyAssets(strategyFrom) + _strategyAssets(strategyTo);

        uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
        // slither-disable-next-line unused-return
        strategyFrom.withdraw(amount, address(this), address(this));
        uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
        uint256 assets = balanceAfter - balanceBefore;

        IERC20(asset()).forceApprove(address(strategyTo), assets);
        // slither-disable-next-line unused-return
        strategyTo.deposit(assets, address(this));

        uint256 assetsAfter = _strategyAssets(strategyFrom) + _strategyAssets(strategyTo);

        uint256 slippage = Math.mulDiv(maxSlippagePercent, amount, PERCENT);
        if (assetsBefore > slippage + assetsAfter) {
            revert TransferredAmountLessThanMin(assetsBefore, assetsAfter, slippage, amount, maxSlippagePercent);
        }

        emit Rebalance(address(strategyFrom), address(strategyTo), assets);
    }

    /// @notice Internal function to calculate the assets held by a strategy
    function _strategyAssets(IBaseVault strategy) private view returns (uint256) {
        return strategy.convertToAssets(strategy.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the number of strategies in the vault
    function strategiesCount() public view returns (uint256) {
        return strategies.length;
    }

    /// @notice Returns true if the strategy is in the vault
    function isStrategy(IBaseVault strategy) public view returns (bool) {
        uint256 length = strategies.length;
        for (uint256 i = 0; i < length; i++) {
            if (strategies[i] == strategy) {
                return true;
            }
        }
        return false;
    }
}
