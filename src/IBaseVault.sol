// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title IBaseVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Interface for the base vault contract
interface IBaseVault is IERC4626 {
    /// @notice Returns the amount of assets that are dead and cannot be withdrawn
    function deadAssets() external view returns (uint256);
}
