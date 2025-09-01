// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAToken} from "@aave/contracts/interfaces/IAToken.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";

import {ReserveConfiguration} from "@aave/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {DataTypes} from "@aave/contracts/protocol/libraries/types/DataTypes.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Auth} from "@src/Auth.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";
import {NonReentrantVault} from "@src/utils/NonReentrantVault.sol";

/// @title AaveStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that invests assets in Aave v3 lending pools
/// @dev Extends NonReentrantVault for Aave v3 integration within the Very Liquid Vault system
/// @dev Reference https://github.com/superform-xyz/super-vaults/blob/8bc1d1bd1579f6fb9a047802256ed3a2bf15f602/src/aave-v3/AaveV3ERC4626Reinvest.sol
contract AaveStrategyVault is NonReentrantVault {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /// @custom:storage-location erc7201:vlv.storage.AaveStrategyVault
  struct AaveStrategyVaultStorage {
    IPool _pool;
    IAToken _aToken;
  }

  // keccak256(abi.encode(uint256(keccak256("vlv.storage.AaveStrategyVault")) - 1)) & ~bytes32(uint256(0xff));
  bytes32 private constant AaveStrategyVaultStorageLocation = 0x45b1d4e37b305e5e54f1e5f5bf73580d91a37bacfc32009c29dd875ef148c600;

  function _getAaveStrategyVaultStorage() private pure returns (AaveStrategyVaultStorage storage $) {
    assembly ("memory-safe") {
      $.slot := AaveStrategyVaultStorageLocation
    }
  }

  /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  error InvalidAsset(address asset);

  /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

  event PoolSet(address indexed pool);
  event ATokenSet(address indexed aToken);

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

  /// @notice Initializes the AaveStrategyVault with an Aave pool
  /// @param auth_ The address of the Auth contract
  /// @param asset_ The address of the asset
  /// @param name_ The name of the vault
  /// @param symbol_ The symbol of the vault
  /// @param fundingAccount The address of the funding account for the first deposit, which will be treated as dead shares
  /// @param firstDepositAmount The amount of the first deposit, which will be treated as dead shares
  /// @param pool_ The address of the Aave pool
  /// @dev Sets the Aave pool and retrieves the corresponding aToken address
  function initialize(Auth auth_, IERC20 asset_, string memory name_, string memory symbol_, address fundingAccount, uint256 firstDepositAmount, IPool pool_) public virtual initializer {
    if (address(pool_) == address(0)) revert NullAddress();
    IAToken aToken_ = IAToken(pool_.getReserveData(address(asset_)).aTokenAddress);
    if (address(aToken_) == address(0)) revert InvalidAsset(address(asset_));

    AaveStrategyVaultStorage storage $ = _getAaveStrategyVaultStorage();
    $._pool = pool_;
    emit PoolSet(address(pool_));
    $._aToken = aToken_;
    emit ATokenSet(address($._aToken));

    super.initialize(auth_, asset_, name_, symbol_, fundingAccount, firstDepositAmount);
  }

  /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Checks Aave reserve configuration and supply cap to determine max deposit
  /// @dev Updates Superform implementation to comply with https://github.com/aave-dao/aave-v3-origin/blob/v3.4.0/src/contracts/protocol/libraries/logic/ValidationLogic.sol#L79-L85
  /// @return The maximum deposit amount allowed by Aave
  function maxDeposit(address receiver) public view override(BaseVault) returns (uint256) {
    // check if asset is paused
    DataTypes.ReserveConfigurationMap memory config = pool().getReserveData(asset()).configuration;
    if (!(config.getActive() && !config.getFrozen() && !config.getPaused())) return 0;

    // handle supply cap
    uint256 supplyCapInWholeTokens = config.getSupplyCap();
    if (supplyCapInWholeTokens == 0) return super.maxDeposit(receiver);

    uint256 tokenDecimals = config.getDecimals();
    uint256 supplyCap = supplyCapInWholeTokens * 10 ** tokenDecimals;
    DataTypes.ReserveDataLegacy memory reserve = pool().getReserveData(asset());
    uint256 usedSupply = (aToken().scaledTotalSupply() + uint256(reserve.accruedToTreasury)).rayMul(reserve.liquidityIndex);

    if (usedSupply >= supplyCap) return 0;
    return Math.min(supplyCap - usedSupply, super.maxDeposit(receiver));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Converts the max deposit amount to shares
  function maxMint(address receiver) public view override(BaseVault) returns (uint256) {
    return Math.min(_convertToShares(maxDeposit(receiver), Math.Rounding.Floor), super.maxMint(receiver));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Limited by both owner's balance and Aave pool liquidity
  function maxWithdraw(address owner) public view override(BaseVault) returns (uint256) {
    // check if asset is paused
    DataTypes.ReserveConfigurationMap memory config = pool().getReserveData(asset()).configuration;
    if (!(config.getActive() && !config.getPaused())) return 0;

    uint256 cash = IERC20(asset()).balanceOf(address(aToken()));
    uint256 assetsBalance = _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    return Math.min(cash < assetsBalance ? cash : assetsBalance, super.maxWithdraw(owner));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Limited by both owner's balance and Aave pool liquidity
  function maxRedeem(address owner) public view override(BaseVault) returns (uint256) {
    // check if asset is paused
    DataTypes.ReserveConfigurationMap memory config = pool().getReserveData(asset()).configuration;
    if (!(config.getActive() && !config.getPaused())) return 0;

    uint256 cash = IERC20(asset()).balanceOf(address(aToken()));
    uint256 cashInShares = _convertToShares(cash, Math.Rounding.Floor);
    uint256 shareBalance = balanceOf(owner);
    return Math.min(cashInShares < shareBalance ? cashInShares : shareBalance, super.maxRedeem(owner));
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Returns the aToken balance since aTokens represent the underlying asset with accrued interest
  /// @dev Round down to avoid stealing assets in roundtrip operations https://github.com/a16z/erc4626-tests/issues/13
  function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
    /// @notice aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
    uint256 liquidityIndex = pool().getReserveNormalizedIncome(address(asset()));
    return Math.mulDiv(aToken().scaledBalanceOf(address(this)), liquidityIndex, WadRayMath.RAY);
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Calls parent deposit then supplies the assets to the Aave pool
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
    super._deposit(caller, receiver, assets, shares);
    IERC20(asset()).forceApprove(address(pool()), assets);
    pool().supply(asset(), assets, address(this), 0);
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Withdraws from the Aave pool then calls parent withdraw
  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    // slither-disable-next-line unused-return
    pool().withdraw(asset(), assets, address(this));
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @notice Returns the Aave pool
  /// @return The Aave pool
  function pool() public view returns (IPool) {
    return _getAaveStrategyVaultStorage()._pool;
  }

  /// @notice Returns the Aave aToken
  /// @return The Aave aToken
  function aToken() public view returns (IAToken) {
    return _getAaveStrategyVaultStorage()._aToken;
  }
}
