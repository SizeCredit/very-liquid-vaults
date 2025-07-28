// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Auth} from "@src/Auth.sol";

/// @title IBaseVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Interface for the base vault contract
interface IBaseVault is IERC4626 {
    /// @notice Emitted when the vault skims idle assets and re-invests them in the underlying protocol
    event Skim();

    /// @notice Returns the address of the auth contract
    function auth() external view returns (Auth);

    /// @notice Returns the total assets cap of the vault
    function totalAssetsCap() external view returns (uint256);

    /// @notice Invests any idle assets held by the strategy
    /// @dev This function should move any assets sitting in the strategy into the underlying protocol
    function skim() external;
}
