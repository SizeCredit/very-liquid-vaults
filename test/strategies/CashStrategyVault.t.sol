// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";

contract CashStrategyVaultTest is BaseTest {
    function test_CashStrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(cashStrategyVault), amount);
        vm.prank(alice);
        cashStrategyVault.deposit(amount, alice);
        assertEq(cashStrategyVault.balanceOf(alice), amount);
        assertEq(cashStrategyVault.totalAssets(), amount);
        assertEq(asset.balanceOf(address(cashStrategyVault)), amount);
        assertEq(asset.balanceOf(alice), 0);
    }

    function test_CashStrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(cashStrategyVault), depositAmount);
        vm.prank(alice);
        cashStrategyVault.deposit(depositAmount, alice);
        assertEq(cashStrategyVault.balanceOf(alice), depositAmount);
        assertEq(cashStrategyVault.totalAssets(), depositAmount);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount);
        assertEq(asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e18;
        vm.prank(alice);
        cashStrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(cashStrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(cashStrategyVault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(alice), withdrawAmount);
    }

    function test_CashStrategyVault_deposit_pullAssets_does_not_change_balanceOf() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(cashStrategyVault), depositAmount);
        vm.prank(alice);
        cashStrategyVault.deposit(depositAmount, alice);
        uint256 shares = cashStrategyVault.balanceOf(alice);
        assertEq(cashStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        cashStrategyVault.pullAssets(bob, pullAmount);
        assertEq(cashStrategyVault.balanceOf(alice), shares);
        assertEq(cashStrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);
    }

    function test_CashStrategyVault_deposit_pullAssets_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(cashStrategyVault), depositAmount);
        vm.prank(alice);
        cashStrategyVault.deposit(depositAmount, alice);
        uint256 shares = cashStrategyVault.balanceOf(alice);
        assertEq(cashStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        cashStrategyVault.pullAssets(bob, pullAmount);
        assertEq(cashStrategyVault.balanceOf(alice), shares);
        assertEq(cashStrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);

        vm.prank(alice);
        cashStrategyVault.redeem(shares, alice, alice);
        assertEq(cashStrategyVault.balanceOf(alice), 0);
        assertEq(cashStrategyVault.totalAssets(), 0);
        assertEq(asset.balanceOf(address(cashStrategyVault)), 0);
        assertEq(asset.balanceOf(alice), depositAmount - pullAmount);
    }

    function test_CashStrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(cashStrategyVault), depositAmount);
        vm.prank(alice);
        cashStrategyVault.deposit(depositAmount, alice);
        uint256 shares = cashStrategyVault.balanceOf(alice);
        assertEq(cashStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(cashStrategyVault), donation);
        assertEq(cashStrategyVault.balanceOf(alice), shares);
        assertEq(cashStrategyVault.balanceOf(bob), 0);
        assertEq(cashStrategyVault.totalAssets(), depositAmount + donation);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount + donation);

        uint256 previewRedeemAssets = cashStrategyVault.previewRedeem(shares);
        uint256 withdrawAmount = depositAmount + donation;
        assertEq(previewRedeemAssets, withdrawAmount - 1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, alice, withdrawAmount, withdrawAmount - 1
            )
        );
        cashStrategyVault.withdraw(withdrawAmount, alice, alice);

        vm.prank(alice);
        cashStrategyVault.withdraw(withdrawAmount - 1, alice, alice);
        assertEq(cashStrategyVault.balanceOf(alice), 0);
        assertEq(cashStrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(cashStrategyVault)), 1);
        assertEq(asset.balanceOf(alice), withdrawAmount - 1);
    }

    function test_CashStrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(cashStrategyVault), depositAmount);
        vm.prank(alice);
        cashStrategyVault.deposit(depositAmount, alice);
        uint256 shares = cashStrategyVault.balanceOf(alice);
        assertEq(cashStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(cashStrategyVault), donation);
        assertEq(cashStrategyVault.balanceOf(alice), shares);
        assertEq(cashStrategyVault.balanceOf(bob), 0);
        assertEq(cashStrategyVault.totalAssets(), depositAmount + donation);
        assertEq(asset.balanceOf(address(cashStrategyVault)), depositAmount + donation);

        uint256 previewWithdrawShares = cashStrategyVault.previewWithdraw(depositAmount + donation);
        assertEq(previewWithdrawShares, shares + 1);

        vm.prank(alice);
        cashStrategyVault.redeem(shares, alice, alice);
        assertEq(cashStrategyVault.balanceOf(alice), 0);
        assertEq(cashStrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(cashStrategyVault)), 1);
        assertEq(asset.balanceOf(alice), depositAmount + donation - 1);
    }
}
