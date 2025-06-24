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
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title ERC4626Strategy
/// @notice A strategy that invests assets in an ERC4626 vault
contract ERC4626Strategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC4626 public vault;

    /*//////////////////////////////////////////////////////////////
                              ERC4626 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setVault(IERC4626 vault_) external onlySizeVaultHasRole(DEFAULT_ADMIN_ROLE) {
        vault = vault_;
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
        vault.withdraw(amount, to, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(vault), assets);
        vault.deposit(assets, address(this));
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        super._withdraw(caller, receiver, owner, assets, shares);
        vault.withdraw(assets, receiver, address(this));
    }
}
