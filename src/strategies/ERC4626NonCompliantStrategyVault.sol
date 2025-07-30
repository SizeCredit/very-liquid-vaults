// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title ERC4626NonCompliantStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that invests assets in an external vault that may not be fully ERC4626-compliant, including fees on deposits/withdrawals
/// @dev Wraps an external ERC4626 vault to provide strategy functionality for the Size Meta Vault
contract ERC4626NonCompliantStrategyVault is ERC4626StrategyVault {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        (shares,) = _deposit2(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override nonReentrant returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        (, assets) = _deposit2(_msgSender(), receiver, assets, shares);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        (shares,) = _withdraw2(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        (, assets) = _withdraw2(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function _deposit2(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        returns (uint256, uint256)
    {
        // If asset() is ERC-777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(this), assets);

        uint256 totalAssetsBefore = totalAssets();
        IERC20(asset()).forceApprove(address(vault), assets);
        // slither-disable-next-line unused-return
        vault.deposit(assets, address(this));
        uint256 totalAssetsAfter = totalAssets();
        assets = totalAssetsAfter - totalAssetsBefore;
        shares = _convertToShares(assets, Math.Rounding.Floor);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);

        __BaseVault_deposit_check(caller, receiver, assets, shares);

        return (shares, assets);
    }

    function _withdraw2(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        returns (uint256, uint256)
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        uint256 assetsBefore = IERC20(asset()).balanceOf(address(this));
        // slither-disable-next-line unused-return
        vault.withdraw(assets, address(this), address(this));
        uint256 assetsAfter = IERC20(asset()).balanceOf(address(this));
        assets = assetsAfter - assetsBefore;
        shares = _convertToShares(assets, Math.Rounding.Ceil);

        // If asset() is ERC-777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);

        __BaseVault_withdraw_check(caller, receiver, owner, assets, shares);

        return (shares, assets);
    }
}
