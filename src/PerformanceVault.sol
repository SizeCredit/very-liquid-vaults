// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title PerformanceVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Vault that collects performance fees
/// @dev performanceFee = (currentPPS - highWaterMark) * totalSupply * feePercent
///      - currentPPS = current price per share = totalAssets() / totalSupply()
///      - highWaterMark = highest PPS previously recorded (stored in state)
///      - feePercent = fee percentage (e.g., 20% = 0.2e18)
///      - totalSupply = total shares in circulation
///      - Fees are only charged when the vault makes a profit, i.e., current PPS > highWaterMark.
/// Reference https://docs.dhedge.org/dhedge-protocol/vault-fees/performance-fees
abstract contract PerformanceVault is BaseVault {
    uint256 public constant PERCENT = 1e18;
    uint256 public constant MAXIMUM_PERFORMANCE_FEE_PERCENT = 0.5e18;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public highWaterMark;
    uint256 public performanceFeePercent;
    address public feeRecipient;
    uint256[47] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error PerformanceFeePercentTooHigh(uint256 performanceFeePercent, uint256 maximumPerformanceFeePercent);

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event PerformanceFeePercentSet(
        uint256 indexed performanceFeePercentBefore, uint256 indexed performanceFeePercentAfter
    );
    event FeeRecipientSet(address indexed feeRecipientBefore, address indexed feeRecipientAfter);
    event HighWaterMarkUpdated(uint256 highWaterMarkBefore, uint256 highWaterMarkAfter);
    event PerformanceFeeMinted(address indexed to, uint256 shares, uint256 assets);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the PerformanceVault with a fee recipient and performance fee percent
    // solhint-disable-next-line func-name-mixedcase
    function __PerformanceVault_init(address feeRecipient_, uint256 performanceFeePercent_) internal onlyInitializing {
        _setFeeRecipient(feeRecipient_);
        _setPerformanceFeePercent(performanceFeePercent_);
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the performance fee percent
    /// @dev Reverts if the performance fee percent is greater than the maximum performance fee percent
    function _setPerformanceFeePercent(uint256 performanceFeePercent_) internal {
        if (performanceFeePercent_ > MAXIMUM_PERFORMANCE_FEE_PERCENT) {
            revert PerformanceFeePercentTooHigh(performanceFeePercent_, MAXIMUM_PERFORMANCE_FEE_PERCENT);
        }

        uint256 performanceFeePercentBefore = performanceFeePercent;

        if (performanceFeePercentBefore == 0 && performanceFeePercent_ > 0) {
            highWaterMark = _pps();
        }

        performanceFeePercent = performanceFeePercent_;
        emit PerformanceFeePercentSet(performanceFeePercentBefore, performanceFeePercent_);
    }

    /// @notice Sets the fee recipient
    function _setFeeRecipient(address feeRecipient_) internal {
        if (feeRecipient_ == address(0)) {
            revert NullAddress();
        }
        address feeRecipientBefore = feeRecipient;
        feeRecipient = feeRecipient_;
        emit FeeRecipientSet(feeRecipientBefore, feeRecipient_);
    }

    /// @notice Returns the price per share
    function _pps() internal view returns (uint256) {
        return Math.mulDiv(totalAssets(), PERCENT, totalSupply());
    }

    /// @notice Updates the high water mark and mints performance fees if applicable
    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);

        if (performanceFeePercent == 0) {
            return;
        }

        uint256 currentPPS = _pps();
        uint256 highWaterMarkBefore = highWaterMark;
        if (currentPPS > highWaterMarkBefore) {
            uint256 profitPerSharePercent = currentPPS - highWaterMarkBefore;
            uint256 totalProfitShares = Math.mulDiv(profitPerSharePercent, totalSupply(), PERCENT);
            uint256 feeShares = Math.mulDiv(totalProfitShares, performanceFeePercent, PERCENT);

            if (feeShares > 0) {
                highWaterMark = currentPPS;
                emit HighWaterMarkUpdated(highWaterMarkBefore, currentPPS);

                _mint(feeRecipient, feeShares);
                emit PerformanceFeeMinted(feeRecipient, feeShares, convertToAssets(feeShares));
            }
        }
    }
}
