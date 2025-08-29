// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Auth} from "@src/Auth.sol";

/// @title IVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Interface for the base vault contract
interface IVault is IERC4626 {
  /// @notice Returns the address of the Auth contract used for permission checks
  /// @dev The Auth contract manages roles and access control for vault operations
  /// @dev External integrators can use this to query permissions but should not rely on its internal logic directly
  function auth() external view returns (Auth);

  /// @notice Returns the maximum amount of underlying assets that the vault can hold.
  /// @dev Expressed in units of the underlying ERC20 `asset()`. A value of type(uint256).max means no cap is enforced. This limit is used to restrict deposits/mints to avoid excessive exposure.
  /// @dev The vault's totalAssets can get higher than the cap in case of donations, accrued yield, etc.
  /// @return The maximum totalAssets allowed in the vault
  function totalAssetsCap() external view returns (uint256);

  /// @notice Returns the price per share
  function pps() external view returns (uint256);
}
