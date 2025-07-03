// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IStrategy is IERC4626 {
    event TransferAssets(address indexed to, uint256 amount);
    event Skim();

    error InvalidAsset(address asset);

    function transferAssets(address to, uint256 amount) external;
    function skim() external;
}
