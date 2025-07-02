// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IStrategy is IERC4626 {
    event PullAssets(address indexed to, uint256 amount);

    error InvalidAsset(address asset);

    function pullAssets(address to, uint256 amount) external;
}
