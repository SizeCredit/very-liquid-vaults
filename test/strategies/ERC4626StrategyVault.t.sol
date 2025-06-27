// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";

contract ERC4626StrategyVaultTest is BaseTest {
    function test_ERC4626StrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(erc4626StrategyVault), amount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(amount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), amount);
        assertEq(erc4626StrategyVault.totalAssets(), amount);
        assertEq(asset.balanceOf(address(vault)), amount);
        assertEq(asset.balanceOf(alice), 0);
    }

    function test_ERC4626StrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount);
        assertEq(asset.balanceOf(address(vault)), depositAmount);
        assertEq(asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e18;
        vm.prank(alice);
        erc4626StrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(address(vault)), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(alice), withdrawAmount);
    }

    function test_ERC4626StrategyVault_deposit_pullAssets_does_not_change_balanceOf() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        erc4626StrategyVault.pullAssets(bob, pullAmount);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(vault)), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);
    }

    function test_ERC4626StrategyVault_deposit_pullAssets_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        erc4626StrategyVault.pullAssets(bob, pullAmount);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(vault)), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);

        uint256 maxRedeem = erc4626StrategyVault.maxRedeem(alice);
        assertEq(maxRedeem, depositAmount - pullAmount);

        uint256 maxWithdraw = erc4626StrategyVault.maxWithdraw(alice);

        vm.prank(alice);
        erc4626StrategyVault.redeem(maxRedeem, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), pullAmount);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount - pullAmount - maxWithdraw);
        assertEq(asset.balanceOf(address(vault)), 0);
        assertEq(asset.balanceOf(alice), maxWithdraw);
    }

    function test_ERC4626StrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount + donation - 1);
        assertEq(asset.balanceOf(address(vault)), depositAmount + donation);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);
        uint256 withdrawAmount = depositAmount + donation - 1;
        assertEq(previewRedeemAssets, withdrawAmount - 1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, alice, withdrawAmount, withdrawAmount - 1
            )
        );
        erc4626StrategyVault.withdraw(withdrawAmount, alice, alice);

        vm.prank(alice);
        erc4626StrategyVault.withdraw(withdrawAmount - 1, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc4626StrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(vault)), 2);
        assertEq(asset.balanceOf(alice), withdrawAmount - 1);
    }

    function test_ERC4626StrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);
        assertEq(erc4626StrategyVault.totalAssets(), depositAmount + donation - 1);
        assertEq(asset.balanceOf(address(vault)), depositAmount + donation);

        uint256 previewWithdrawShares = erc4626StrategyVault.previewWithdraw(depositAmount + donation - 1);
        assertEq(previewWithdrawShares, shares + 1);

        vm.prank(alice);
        erc4626StrategyVault.redeem(shares, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc4626StrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(vault)), 2);
        assertEq(asset.balanceOf(alice), depositAmount + donation - 2);
    }
}
