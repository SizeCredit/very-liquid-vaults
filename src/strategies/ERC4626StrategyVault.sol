// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/SizeVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title ERC4626StrategyVault
/// @notice A strategy that invests assets in an ERC4626 vault
contract ERC4626StrategyVault is BaseStrategyVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC4626 public vault;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event VaultSet(address indexed vaultBefore, address indexed vaultAfter);

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error VaultAlreadySet();

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setVault(IERC4626 vault_) external onlySizeVaultHasRole(DEFAULT_ADMIN_ROLE) {
        if (address(vault) != address(0)) {
            revert VaultAlreadySet();
        }
        vault = vault_;
        emit VaultSet(address(0), address(vault_));
    }

    function pullAssets(address to, uint256 amount)
        external
        override
        whenNotPausedAndSizeVaultNotPaused
        onlySizeVault
        nonReentrant
        notNullAddress(to)
    {
        vault.withdraw(amount, to, address(this));
        emit PullAssets(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxWithdraw(owner);
    }

    function maxMint(address receiver) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxMint(receiver);
    }

    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxRedeem(owner);
    }

    function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(vault), assets);
        vault.deposit(assets, address(this));
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        vault.withdraw(assets, receiver, address(this));
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
