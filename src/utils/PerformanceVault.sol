// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";

/// @title PerformanceVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Vault that collects performance fees
/// @dev Reference https://docs.dhedge.org/dhedge-protocol/vault-fees/performance-fees
abstract contract PerformanceVault is BaseVault {
  /// @dev Constant representing the maximum performance fee in PERCENT
  uint256 private constant MAXIMUM_PERFORMANCE_FEE_PERCENT = 0.5e18;

  // STORAGE
  /// @custom:storage-location erc7201:vlv.storage.PerformanceVault
  struct PerformanceVaultStorage {
    uint256 _highWaterMark;
    uint256 _performanceFeePercent;
    address _feeRecipient;
  }

  // keccak256(abi.encode(uint256(keccak256("vlv.storage.PerformanceVault")) - 1)) & ~bytes32(uint256(0xff));
  bytes32 private constant PerformanceVaultStorageLocation = 0x8133214f360747da779e5436efd7332b025d67830fc92a23fa9b9e5e4b87fd00;

  function _getPerformanceVaultStorage() private pure returns (PerformanceVaultStorage storage $) {
    assembly {
      $.slot := PerformanceVaultStorageLocation
    }
  }

  // ERRORS
  error PerformanceFeePercentTooHigh(uint256 performanceFeePercent, uint256 maximumPerformanceFeePercent);

  // EVENTS
  event PerformanceFeePercentSet(uint256 indexed performanceFeePercentBefore, uint256 indexed performanceFeePercentAfter);
  event FeeRecipientSet(address indexed feeRecipientBefore, address indexed feeRecipientAfter);
  event HighWaterMarkUpdated(uint256 highWaterMarkBefore, uint256 highWaterMarkAfter);
  event PerformanceFeeMinted(address indexed to, uint256 shares, uint256 assets);

  // INITIALIZER
  /// @notice Initializes the PerformanceVault with a fee recipient and performance fee percent
  /// @param feeRecipient_ The address of the fee recipient
  /// @param performanceFeePercent_ The performance fee percent
  // solhint-disable-next-line func-name-mixedcase
  function __PerformanceVault_init(address feeRecipient_, uint256 performanceFeePercent_) internal onlyInitializing {
    _setFeeRecipient(feeRecipient_);
    _setPerformanceFeePercent(performanceFeePercent_);
  }

  // MODIFIERS
  /// @notice Modifier to ensure the performance fee is minted before the function is executed
  modifier mintPerformanceFee() {
    _mintPerformanceFee();
    _;
  }

  // INTERNAL/PRIVATE
  /// @notice Sets the performance fee percent
  /// @param performanceFeePercent_ The new performance fee percent
  /// @dev Reverts if the performance fee percent is greater than the maximum performance fee percent
  function _setPerformanceFeePercent(uint256 performanceFeePercent_) internal {
    if (performanceFeePercent_ > MAXIMUM_PERFORMANCE_FEE_PERCENT) revert PerformanceFeePercentTooHigh(performanceFeePercent_, MAXIMUM_PERFORMANCE_FEE_PERCENT);

    PerformanceVaultStorage storage $ = _getPerformanceVaultStorage();
    uint256 performanceFeePercentBefore = $._performanceFeePercent;
    uint256 highWaterMarkBefore = $._highWaterMark;
    uint256 currentPPS = _pps();
    // slither-disable-next-line incorrect-equality
    if (performanceFeePercentBefore == 0 && performanceFeePercent_ > 0 && highWaterMarkBefore < currentPPS) _setHighWaterMark(currentPPS);

    $._performanceFeePercent = performanceFeePercent_;
    emit PerformanceFeePercentSet(performanceFeePercentBefore, performanceFeePercent_);
  }

  /// @notice Sets the fee recipient
  /// @param feeRecipient_ The new fee recipient
  function _setFeeRecipient(address feeRecipient_) internal {
    if (feeRecipient_ == address(0)) revert NullAddress();

    PerformanceVaultStorage storage $ = _getPerformanceVaultStorage();
    address feeRecipientBefore = $._feeRecipient;
    $._feeRecipient = feeRecipient_;
    emit FeeRecipientSet(feeRecipientBefore, feeRecipient_);
  }

  /// @notice Returns the price per share
  function _pps() private view returns (uint256) {
    uint256 totalAssets_ = totalAssets();
    uint256 totalSupply_ = totalSupply();
    return totalSupply_ > 0 ? Math.mulDiv(totalAssets_, PERCENT, totalSupply_) : PERCENT;
  }

  /// @notice Mints performance fees if applicable
  /// @dev Using `convertToShares(feeShares)` would not be correct because once those shares are minted, the PPS changes,
  ///        and the asset value of the minted shares is different to feeAssets.
  ///        We solve the equation: feeAssets = feeShares * (totalAssets + 1) / (totalSupply + 1 + feeShares)
  ///        Basically feeAssets = convertToAssets(feeShares), but adding feeShares to the totalSupply part during the calculation
  function _mintPerformanceFee() private {
    PerformanceVaultStorage storage $ = _getPerformanceVaultStorage();
    if ($._performanceFeePercent == 0) return;

    uint256 currentPPS = _pps();
    uint256 highWaterMarkBefore = $._highWaterMark;
    if (currentPPS > highWaterMarkBefore) {
      uint256 profitPerSharePercent = currentPPS - highWaterMarkBefore;
      uint256 totalProfitAssets = Math.mulDiv(profitPerSharePercent, totalSupply(), PERCENT);
      uint256 feeAssets = Math.mulDiv(totalProfitAssets, $._performanceFeePercent, PERCENT);
      uint256 feeShares = Math.mulDiv(feeAssets, totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1 - feeAssets);

      if (feeShares > 0) {
        _mint($._feeRecipient, feeShares);
        _setHighWaterMark(_pps());
        emit PerformanceFeeMinted($._feeRecipient, feeShares, feeAssets);
      }
    }
  }

  /// @notice Sets the high water mark
  /// @param highWaterMark_ The new high water mark
  function _setHighWaterMark(uint256 highWaterMark_) internal {
    PerformanceVaultStorage storage $ = _getPerformanceVaultStorage();
    uint256 highWaterMarkBefore = $._highWaterMark;
    $._highWaterMark = highWaterMark_;
    emit HighWaterMarkUpdated(highWaterMarkBefore, highWaterMark_);
  }

  // ERC4626 OVERRIDES
  /// @inheritdoc BaseVault
  /// @dev Prevents reentrancy, mints performance fees
  function deposit(uint256 assets, address receiver) public override(BaseVault) nonReentrant mintPerformanceFee returns (uint256) {
    return super.deposit(assets, receiver);
  }

  /// @inheritdoc BaseVault
  /// @dev Prevents reentrancy, mints performance fees
  function mint(uint256 shares, address receiver) public override(BaseVault) nonReentrant mintPerformanceFee returns (uint256) {
    return super.mint(shares, receiver);
  }

  /// @inheritdoc BaseVault
  /// @dev Prevents reentrancy, mints performance fees
  function withdraw(uint256 assets, address receiver, address owner) public override(BaseVault) nonReentrant mintPerformanceFee returns (uint256) {
    return super.withdraw(assets, receiver, owner);
  }

  /// @inheritdoc BaseVault
  /// @dev Prevents reentrancy, mints performance fees
  function redeem(uint256 shares, address receiver, address owner) public override(BaseVault) nonReentrant mintPerformanceFee returns (uint256) {
    return super.redeem(shares, receiver, owner);
  }

  // VIEW FUNCTIONS
  /// @notice Returns the high water mark
  function highWaterMark() public view nonReentrantView returns (uint256) {
    return _highWaterMark();
  }

  /// @notice Internal function to return the high water mark
  function _highWaterMark() private view returns (uint256) {
    return _getPerformanceVaultStorage()._highWaterMark;
  }

  /// @notice Returns the performance fee percent
  function performanceFeePercent() public view nonReentrantView returns (uint256) {
    return _performanceFeePercent();
  }

  /// @notice Internal function to return the performance fee percent
  function _performanceFeePercent() private view returns (uint256) {
    return _getPerformanceVaultStorage()._performanceFeePercent;
  }

  /// @notice Returns the fee recipient
  function feeRecipient() public view nonReentrantView returns (address) {
    return _feeRecipient();
  }

  /// @notice Internal function to return the fee recipient
  function _feeRecipient() private view returns (address) {
    return _getPerformanceVaultStorage()._feeRecipient;
  }
}
