// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IBaseVault} from "@src/IBaseVault.sol";

/// @title IStrategy
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Interface for vault strategies that can be used by the SizeMetaVault
/// @dev Extends IBaseVault to provide additional strategy-specific functionality
interface IStrategy is IBaseVault {
    /// @notice Emitted when assets are transferred from this strategy to another address
    /// @param to The recipient address of the transferred assets
    /// @param amount The amount of assets transferred
    event TransferAssets(address indexed to, uint256 amount);

    /// @notice Emitted when the strategy skims idle assets and invests them
    event Skim();

    /// @notice Thrown when an invalid asset is provided to the strategy
    /// @param asset The invalid asset address
    error InvalidAsset(address asset);

    /// @notice Transfers assets from this strategy to another address
    /// @dev Can only be called by SizeMetaVault
    /// @param to The recipient address for the transferred assets
    /// @param amount The amount of assets to transfer
    function transferAssets(address to, uint256 amount) external;

    /// @notice Invests any idle assets held by the strategy
    /// @dev This function should move any assets sitting in the strategy into the underlying protocol
    function skim() external;
}
