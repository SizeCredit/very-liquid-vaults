// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {BaseStrategy} from "@src/strategies/BaseStrategy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";
import {IPool} from "@deps/aave/interfaces/IPool.sol";

/// @title AaveStrategy
/// @notice A strategy that invests assets in Aave
contract AaveStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IPool public pool;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event PoolSet(address indexed poolBefore, address indexed poolAfter);

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setPool(IPool pool_) external notNullAddress(address(pool_)) onlySizeVaultHasRole(DEFAULT_ADMIN_ROLE) {
        emit PoolSet(address(pool), address(pool_));
        pool = pool_;
    }

    function pullAssets(address to, uint256 amount)
        external
        override
        whenNotPausedAndSizeVaultNotPaused
        onlySizeVault
        nonReentrant
        notNullAddress(to)
    {
        emit PullAssets(to, amount);
        pool.withdraw(asset(), amount, to);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(pool), assets);
        pool.supply(asset(), assets, address(this), 0);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        super._withdraw(caller, receiver, owner, assets, shares);
        pool.withdraw(asset(), assets, receiver);
    }
}
