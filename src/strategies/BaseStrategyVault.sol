// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeVault} from "@src/SizeVault.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {Auth} from "@src/Auth.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseStrategyVault is IStrategy, BaseVault {
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    SizeVault public sizeVault;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAsset();

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event PullAssets(address indexed to, uint256 amount);
}
