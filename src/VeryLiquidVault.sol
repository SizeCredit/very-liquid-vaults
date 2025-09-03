// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Auth, DEFAULT_ADMIN_ROLE, GUARDIAN_ROLE, STRATEGIST_ROLE, VAULT_MANAGER_ROLE} from "@src/Auth.sol";
import {IVault} from "@src/IVault.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";
import {PerformanceVault} from "@src/utils/PerformanceVault.sol";

/// @title VeryLiquidVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Very Liquid Vault that distributes assets across multiple strategies
/// @dev Extends PerformanceVault to manage multiple strategy vaults for asset allocation. By default, the performance fee is 0.
contract VeryLiquidVault is PerformanceVault {
  using SafeERC20 for IERC20;

  /// @dev The maximum number of strategies that can be added to the vault
  uint256 public constant MAX_STRATEGIES = 10;
  /// @dev The default maximum slippage percent for rebalancing in PERCENT
  uint256 public constant DEFAULT_MAX_SLIPPAGE_PERCENT = 0.01e18;

  // STORAGE
  /// @custom:storage-location erc7201:vlv.storage.VeryLiquidVault
  struct VeryLiquidVaultStorage {
    IVault[] _strategies;
    uint256 _rebalanceMaxSlippagePercent;
  }

  // keccak256(abi.encode(uint256(keccak256("vlv.storage.VeryLiquidVault")) - 1)) & ~bytes32(uint256(0xff));
  bytes32 private constant VeryLiquidVaultStorageLocation = 0x851713d8b7886cdb5682ccb4d2dba1bf8cae30c699ce588016da31dab5d7f100;

  function _getVeryLiquidVaultStorage() private pure returns (VeryLiquidVaultStorage storage $) {
    assembly {
      $.slot := VeryLiquidVaultStorageLocation
    }
  }

  // EVENTS
  event StrategyAdded(address indexed strategy);
  event StrategyRemoved(address indexed strategy);
  event StrategyReordered(address indexed strategyOld, address indexed strategyNew, uint256 indexed index);
  event Rebalanced(address indexed strategyFrom, address indexed strategyTo, uint256 rebalancedAmount, uint256 maxSlippagePercent);
  event RebalanceMaxSlippagePercentSet(uint256 oldRebalanceMaxSlippagePercent, uint256 newRebalanceMaxSlippagePercent);
  event DepositFailed(address indexed strategy, uint256 amount);
  event WithdrawFailed(address indexed strategy, uint256 amount);

  // ERRORS
  error InvalidStrategy(address strategy);
  error CannotDepositToStrategies(uint256 assets, uint256 shares, uint256 remainingAssets);
  error CannotWithdrawFromStrategies(uint256 assets, uint256 shares, uint256 missingAssets);
  error TransferredAmountLessThanMin(uint256 assetsBefore, uint256 assetsAfter, uint256 slippage, uint256 amount, uint256 maxSlippagePercent);
  error MaxStrategiesExceeded(uint256 strategiesCount, uint256 maxStrategies);
  error ArrayLengthMismatch(uint256 expectedLength, uint256 actualLength);
  error InvalidMaxSlippagePercent(uint256 maxSlippagePercent);

  // CONSTRUCTOR / INITIALIZER
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the VeryLiquidVault with strategies
  /// @param auth_ The address of the Auth contract
  /// @param asset_ The address of the asset
  /// @param name_ The name of the vault
  /// @param symbol_ The symbol of the vault
  /// @param fundingAccount The address of the funding account for the first deposit, which will be treated as dead shares
  /// @param firstDepositAmount The amount of the first deposit, which will be treated as dead shares
  /// @param strategies_ The initial strategies to add to the vault
  function initialize(Auth auth_, IERC20 asset_, string memory name_, string memory symbol_, address fundingAccount, uint256 firstDepositAmount, IVault[] memory strategies_)
    public
    virtual
    initializer
  {
    __PerformanceVault_init(auth_.getRoleMember(DEFAULT_ADMIN_ROLE, 0), 0);

    for (uint256 i = 0; i < strategies_.length; ++i) {
      _addStrategy(strategies_[i], address(asset_), address(auth_));
    }
    _setRebalanceMaxSlippagePercent(DEFAULT_MAX_SLIPPAGE_PERCENT);

    super.initialize(auth_, asset_, name_, symbol_, fundingAccount, firstDepositAmount);
  }

  // ERC4626 OVERRIDES
  /// @inheritdoc ERC4626Upgradeable
  /// @dev The maximum amount that can be deposited is the minimum between this receiver specific limit and the maximum asset amount that can be deposited to all strategies
  function maxDeposit(address receiver) public view override(BaseVault) returns (uint256) {
    return Math.min(_maxDepositToStrategies(), super.maxDeposit(receiver));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The maximum amount that can be minted is the minimum between this receiver specific limit and the maximum asset amount that can be minted to all strategies, converted to shares
  function maxMint(address receiver) public view override(BaseVault) returns (uint256) {
    uint256 maxDepositReceiver = maxDeposit(receiver);
    // slither-disable-next-line incorrect-equality
    uint256 maxDepositInShares = maxDepositReceiver == type(uint256).max ? type(uint256).max : _convertToShares(maxDepositReceiver, Math.Rounding.Floor);
    return Math.min(maxDepositInShares, super.maxMint(receiver));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The maximum amount that can be withdrawn is the minimum between this owner specific limit and the maximum asset amount that can be withdrawn from all strategies
  function maxWithdraw(address owner) public view override(BaseVault) returns (uint256) {
    return Math.min(_maxWithdrawFromStrategies(), super.maxWithdraw(owner));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The maximum amount that can be redeemed is the minimum between this owner specific limit and the maximum asset amount that can be redeemed from all strategies, converted to shares
  function maxRedeem(address owner) public view override(BaseVault) returns (uint256) {
    uint256 maxWithdrawOwner = maxWithdraw(owner);
    // slither-disable-next-line incorrect-equality
    uint256 maxWithdrawInShares = maxWithdrawOwner == type(uint256).max ? type(uint256).max : _convertToShares(maxWithdrawOwner, Math.Rounding.Floor);
    return Math.min(maxWithdrawInShares, super.maxRedeem(owner));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The total assets is the sum of the assets in all strategies
  // slither-disable-next-line calls-loop
  function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256 total) {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      IVault strategy = $._strategies[i];
      total += strategy.convertToAssets(strategy.balanceOf(address(this)));
    }
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Tries to deposit to strategies sequentially, reverts if not all assets can be deposited
  // slither-disable-next-line calls-loop
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
    if (_isInitializing()) {
      // first deposit
      shares = assets;
    }

    super._deposit(caller, receiver, assets, shares);

    uint256 assetsToDeposit = assets;

    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      // slither-disable-next-line incorrect-equality
      if (assetsToDeposit == 0) break;
      IVault strategy = $._strategies[i];
      uint256 strategyMaxDeposit = strategy.maxDeposit(address(this));
      uint256 depositAmount = Math.min(assetsToDeposit, strategyMaxDeposit);

      if (depositAmount > 0) {
        IERC20(asset()).forceApprove(address(strategy), depositAmount);
        // slither-disable-next-line unused-return
        try strategy.deposit(depositAmount, address(this)) {
          assetsToDeposit -= depositAmount;
        } catch {
          emit DepositFailed(address(strategy), depositAmount);
          IERC20(asset()).forceApprove(address(strategy), 0);
        }
      }
    }
    if (assetsToDeposit > 0) revert CannotDepositToStrategies(assets, shares, assetsToDeposit);
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Tries to withdraw from strategies sequentially, reverts if not enough assets available
  // slither-disable-next-line calls-loop
  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    uint256 assetsToWithdraw = assets;

    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      // slither-disable-next-line incorrect-equality
      if (assetsToWithdraw == 0) break;
      IVault strategy = $._strategies[i];

      uint256 strategyMaxWithdraw = strategy.maxWithdraw(address(this));
      uint256 withdrawAmount = Math.min(assetsToWithdraw, strategyMaxWithdraw);

      if (withdrawAmount > 0) {
        // slither-disable-next-line unused-return
        try strategy.withdraw(withdrawAmount, address(this), address(this)) {
          assetsToWithdraw -= withdrawAmount;
        } catch {
          emit WithdrawFailed(address(strategy), withdrawAmount);
        }
      }
    }
    if (assetsToWithdraw > 0) revert CannotWithdrawFromStrategies(assets, shares, assetsToWithdraw);

    super._withdraw(caller, receiver, owner, assets, shares);
  }

  // ADMIN FUNCTIONS
  /// @notice Sets the performance fee percent
  /// @param performanceFeePercent_ The new performance fee percent
  /// @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
  function setPerformanceFeePercent(uint256 performanceFeePercent_) external nonReentrant onlyAuth(DEFAULT_ADMIN_ROLE) {
    _setPerformanceFeePercent(performanceFeePercent_);
  }

  /// @notice Sets the fee recipient
  /// @param feeRecipient_ The new fee recipient
  /// @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
  function setFeeRecipient(address feeRecipient_) external nonReentrant onlyAuth(DEFAULT_ADMIN_ROLE) {
    _setFeeRecipient(feeRecipient_);
  }

  // VAULT MANAGER FUNCTIONS
  /// @notice Sets the rebalance max slippage percent
  /// @param rebalanceMaxSlippagePercent_ The new rebalance max slippage percent
  /// @dev Only callable by addresses with VAULT_MANAGER_ROLE
  function setRebalanceMaxSlippagePercent(uint256 rebalanceMaxSlippagePercent_) external nonReentrant onlyAuth(VAULT_MANAGER_ROLE) {
    _setRebalanceMaxSlippagePercent(rebalanceMaxSlippagePercent_);
  }

  /// @notice Adds a new strategy to the vault
  /// @param strategy_ The new strategy to add
  /// @dev Only callable by addresses with VAULT_MANAGER_ROLE
  function addStrategy(IVault strategy_) external nonReentrant emitVaultStatus onlyAuth(VAULT_MANAGER_ROLE) {
    _addStrategy(strategy_, asset(), address(auth()));
  }

  // GUARDIAN FUNCTIONS
  /// @notice Removes a strategy from the vault and transfers all assets, if any, to another strategy
  /// @param strategyToRemove The strategy to remove
  /// @param strategyToReceiveAssets The strategy to receive the assets
  /// @param amount The amount of assets to transfer
  /// @param maxSlippagePercent The maximum slippage percent allowed for the rebalance
  /// @dev Only callable by addresses with GUARDIAN_ROLE
  /// @dev Using `amount` = 0 will forfeit all assets from `strategyToRemove`
  /// @dev Using `amount` = type(uint256).max will attempt to transfer the entire balance from `strategyToRemove`
  /// @dev If `convertToAssets(balanceOf)` > `maxWithdraw`, e.g. due to pause/withdraw limits, the _rebalance step will revert, so an appropriate `amount` should be used
  /// @dev Reverts if totalAssets() == 0 at the end of the operation, which can happen if the call is performed with 100% slippage
  // slither-disable-next-line reentrancy-no-eth
  function removeStrategy(IVault strategyToRemove, IVault strategyToReceiveAssets, uint256 amount, uint256 maxSlippagePercent) external nonReentrant emitVaultStatus onlyAuth(GUARDIAN_ROLE) {
    if (!_isStrategy(strategyToRemove)) revert InvalidStrategy(address(strategyToRemove));
    if (!_isStrategy(strategyToReceiveAssets)) revert InvalidStrategy(address(strategyToReceiveAssets));
    if (strategyToRemove == strategyToReceiveAssets) revert InvalidStrategy(address(strategyToReceiveAssets));

    if (amount > 0) {
      uint256 assetsToRemove = strategyToRemove.convertToAssets(strategyToRemove.balanceOf(address(this)));
      amount = Math.min(amount, assetsToRemove);
      _rebalance(strategyToRemove, strategyToReceiveAssets, amount, maxSlippagePercent);
    }
    _removeStrategy(strategyToRemove);

    // slither-disable-next-line incorrect-equality
    if (totalAssets() == 0) revert NullAmount();
  }

  // STRATEGIST FUNCTIONS
  /// @notice Reorders the strategies
  /// @param newStrategiesOrder The new strategies order
  /// @dev Only callable by addresses with STRATEGIST_ROLE
  /// @dev Verifies that the new strategies order is valid and that there are no duplicates
  /// @dev Clears current strategies and adds them in the new order
  function reorderStrategies(IVault[] calldata newStrategiesOrder) external nonReentrant notPaused onlyAuth(STRATEGIST_ROLE) {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    if (length != newStrategiesOrder.length) revert ArrayLengthMismatch(length, newStrategiesOrder.length);

    for (uint256 i = 0; i < length; ++i) {
      if (!_isStrategy(newStrategiesOrder[i])) revert InvalidStrategy(address(newStrategiesOrder[i]));
      for (uint256 j = i + 1; j < length; ++j) {
        if (newStrategiesOrder[i] == newStrategiesOrder[j]) revert InvalidStrategy(address(newStrategiesOrder[i]));
      }
    }

    for (uint256 i = 0; i < length; ++i) {
      IVault strategyOld = $._strategies[i];
      $._strategies[i] = newStrategiesOrder[i];
      emit StrategyReordered(address(strategyOld), address(newStrategiesOrder[i]), i);
    }
  }

  /// @notice Rebalances assets between two strategies
  /// @param strategyFrom The strategy to transfer assets from
  /// @param strategyTo The strategy to transfer assets to
  /// @param amount The amount of assets to transfer
  /// @param maxSlippagePercent The maximum slippage percent allowed for the rebalance
  /// @dev Only callable by addresses with STRATEGIST_ROLE
  /// @dev Transfers assets from one strategy to another
  /// @dev We have maxSlippagePercent <= PERCENT since rebalanceMaxSlippagePercent has already been checked in setRebalanceMaxSlippagePercent
  function rebalance(IVault strategyFrom, IVault strategyTo, uint256 amount, uint256 maxSlippagePercent) external nonReentrant notPaused emitVaultStatus onlyAuth(STRATEGIST_ROLE) {
    maxSlippagePercent = Math.min(maxSlippagePercent, _rebalanceMaxSlippagePercent());

    if (!_isStrategy(strategyFrom)) revert InvalidStrategy(address(strategyFrom));
    if (!_isStrategy(strategyTo)) revert InvalidStrategy(address(strategyTo));
    if (strategyFrom == strategyTo) revert InvalidStrategy(address(strategyTo));
    if (amount == 0) revert NullAmount();

    _rebalance(strategyFrom, strategyTo, amount, maxSlippagePercent);
  }

  // PRIVATE FUNCTIONS
  /// @notice Internal function to add a strategy
  /// @param strategy_ The strategy to add
  /// @param asset_ The asset of the strategy
  /// @param auth_ The auth of the strategy
  /// @dev Strategy configuration is assumed to be correct (non-malicious, no circular dependencies, etc.)
  // slither-disable-next-line calls-loop
  function _addStrategy(IVault strategy_, address asset_, address auth_) private {
    if (address(strategy_) == address(0)) revert NullAddress();
    if (_isStrategy(strategy_)) revert InvalidStrategy(address(strategy_));
    if (strategy_.asset() != asset_ || address(strategy_.auth()) != auth_) revert InvalidStrategy(address(strategy_));

    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    $._strategies.push(strategy_);
    emit StrategyAdded(address(strategy_));
    if ($._strategies.length > MAX_STRATEGIES) revert MaxStrategiesExceeded($._strategies.length, MAX_STRATEGIES);
  }

  /// @notice Internal function to remove a strategy
  /// @param strategy The strategy to remove
  /// @dev No NullAddress check is needed because only whitelisted strategies can be removed, and it is checked in _addStrategy
  /// @dev Removes the strategy in-place to keep the order
  function _removeStrategy(IVault strategy) private {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    for (uint256 i = 0; i < $._strategies.length; ++i) {
      if ($._strategies[i] == strategy) {
        for (uint256 j = i; j < $._strategies.length - 1; ++j) {
          $._strategies[j] = $._strategies[j + 1];
        }
        $._strategies.pop();
        emit StrategyRemoved(address(strategy));
        break;
      }
    }
  }

  /// @notice Internal function to set the default max slippage percent
  /// @param rebalanceMaxSlippagePercent_ The new rebalance max slippage percent
  function _setRebalanceMaxSlippagePercent(uint256 rebalanceMaxSlippagePercent_) private {
    if (rebalanceMaxSlippagePercent_ > PERCENT) revert InvalidMaxSlippagePercent(rebalanceMaxSlippagePercent_);

    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 oldRebalanceMaxSlippagePercent = $._rebalanceMaxSlippagePercent;
    $._rebalanceMaxSlippagePercent = rebalanceMaxSlippagePercent_;
    emit RebalanceMaxSlippagePercentSet(oldRebalanceMaxSlippagePercent, rebalanceMaxSlippagePercent_);
  }

  /// @notice Internal function to calculate maximum depositable amount in all strategies
  /// @dev The maximum amount that can be deposited to all strategies is the sum of the maximum amount that can be deposited to each strategy
  /// @dev This value might be overstated if nested strategies are used. For example, if a very liquid has two strategies, one of which is an ERC4626StrategyVault and the other is a VeryLiquidVault that has the same ERC4626StrategyVault instance. In this scenario, if the ERC-4626 strategy has 100 maxDeposit remaining, the top-level very liquid would double count this value and return 200. However, in practice, trying to deposit 200 would cause a revert, because only 100 can be deposited.
  // slither-disable-next-line calls-loop
  function _maxDepositToStrategies() private view returns (uint256 maxAssets) {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      maxAssets = Math.saturatingAdd(maxAssets, $._strategies[i].maxDeposit(address(this)));
    }
  }

  /// @notice Internal function to calculate maximum withdrawable amount from all strategies
  /// @dev The maximum amount that can be withdrawn from all strategies is the sum of the maximum amount that can be withdrawn from each strategy
  /// @dev This value might be overstated if nested strategies are used. For example, if a very liquid has two strategies, one of which is an ERC4626StrategyVault and the other is a VeryLiquidVault that has the same ERC4626StrategyVault instance. In this scenario, if the ERC-4626 strategy has 100 maxWithdraw remaining, the top-level very liquid would double count this value and return 200. However, in practice, trying to withdraw 200 would cause a revert, because only 100 can be withdrawn.
  // slither-disable-next-line calls-loop
  function _maxWithdrawFromStrategies() private view returns (uint256 maxAssets) {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      maxAssets = Math.saturatingAdd(maxAssets, $._strategies[i].maxWithdraw(address(this)));
    }
  }

  /// @notice Internal function to rebalance assets between two strategies
  /// @dev If before - after > maxSlippagePercent * amount, the _rebalance operation reverts
  /// @dev Assumes input is validated by caller functions
  /// @param strategyFrom The strategy to transfer assets from
  /// @param strategyTo The strategy to transfer assets to
  /// @param amount The amount of assets to transfer
  /// @param maxSlippagePercent The maximum slippage percent allowed for the rebalance
  function _rebalance(IVault strategyFrom, IVault strategyTo, uint256 amount, uint256 maxSlippagePercent) private {
    uint256 assetsBefore = strategyFrom.convertToAssets(strategyFrom.balanceOf(address(this))) + strategyTo.convertToAssets(strategyTo.balanceOf(address(this)));

    uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
    if (amount > 0) {
      // slither-disable-next-line unused-return
      strategyFrom.withdraw(amount, address(this), address(this));
    }
    uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
    uint256 assets = balanceAfter - balanceBefore;

    if (assets > 0) {
      IERC20(asset()).forceApprove(address(strategyTo), assets);
      // slither-disable-next-line unused-return
      strategyTo.deposit(assets, address(this));
    }

    uint256 assetsAfter = strategyFrom.convertToAssets(strategyFrom.balanceOf(address(this))) + strategyTo.convertToAssets(strategyTo.balanceOf(address(this)));

    uint256 slippage = Math.mulDiv(maxSlippagePercent, amount, PERCENT);
    if (assetsBefore > slippage + assetsAfter) revert TransferredAmountLessThanMin(assetsBefore, assetsAfter, slippage, amount, maxSlippagePercent);

    emit Rebalanced(address(strategyFrom), address(strategyTo), assets, maxSlippagePercent);
  }

  // VIEW FUNCTIONS
  /// @notice Returns the strategies in the vault
  /// @return The strategies in the vault
  function strategies() public view nonReentrantView returns (IVault[] memory) {
    return _strategies();
  }

  /// @notice Returns the strategies in the vault
  function _strategies() private view returns (IVault[] memory) {
    return _getVeryLiquidVaultStorage()._strategies;
  }

  /// @notice Returns the strategy at the given index
  /// @param index The index of the strategy
  /// @return The strategy at the given index
  function strategies(uint256 index) public view nonReentrantView returns (IVault) {
    return _getVeryLiquidVaultStorage()._strategies[index];
  }

  /// @notice Returns the number of strategies in the vault
  /// @return The number of strategies in the vault
  function strategiesCount() public view nonReentrantView returns (uint256) {
    return strategies().length;
  }

  /// @notice Returns the rebalance max slippage percent
  /// @return The rebalance max slippage percent
  function rebalanceMaxSlippagePercent() public view nonReentrantView returns (uint256) {
    return _rebalanceMaxSlippagePercent();
  }

  /// @notice Returns the rebalance max slippage percent
  function _rebalanceMaxSlippagePercent() private view returns (uint256) {
    return _getVeryLiquidVaultStorage()._rebalanceMaxSlippagePercent;
  }

  /// @notice Returns true if the strategy is in the vault
  /// @param strategy The strategy to check
  /// @return True if the strategy is in the vault
  function isStrategy(IVault strategy) public view nonReentrantView returns (bool) {
    return _isStrategy(strategy);
  }

  /// @notice Returns true if the strategy is in the vault
  function _isStrategy(IVault strategy) private view returns (bool) {
    VeryLiquidVaultStorage storage $ = _getVeryLiquidVaultStorage();
    uint256 length = $._strategies.length;
    for (uint256 i = 0; i < length; ++i) {
      if ($._strategies[i] == strategy) return true;
    }
    return false;
  }
}
