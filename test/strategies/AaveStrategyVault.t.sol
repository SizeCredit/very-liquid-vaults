// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";

contract AaveStrategyVaultTest is BaseTest {
    function test_AaveStrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(aaveStrategyVault), amount);
        vm.prank(alice);
        aaveStrategyVault.deposit(amount, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), amount);
        assertEq(aaveStrategyVault.totalAssets(), amount);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), amount);
        assertEq(asset.balanceOf(alice), 0);
    }

    function test_AaveStrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), depositAmount);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount);
        assertEq(asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e18;
        vm.prank(alice);
        aaveStrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(alice), withdrawAmount);
    }

    function test_AaveStrategyVault_deposit_pullAssets_does_not_change_balanceOf() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        aaveStrategyVault.pullAssets(bob, pullAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);
    }

    function test_AaveStrategyVault_deposit_pullAssets_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e18;
        vm.prank(address(sizeVault));
        aaveStrategyVault.pullAssets(bob, pullAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount - pullAmount);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount - pullAmount);
        assertEq(asset.balanceOf(bob), pullAmount);

        vm.prank(alice);
        aaveStrategyVault.redeem(shares, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), 0);
        assertEq(aaveStrategyVault.totalAssets(), 0);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), 0);
        assertEq(asset.balanceOf(alice), depositAmount - pullAmount);
    }

    function test_AaveStrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(aaveStrategyVault), donation);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.balanceOf(bob), 0);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount + donation);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount + donation);

        uint256 previewRedeemAssets = aaveStrategyVault.previewRedeem(shares);
        uint256 withdrawAmount = depositAmount + donation;
        assertEq(previewRedeemAssets, withdrawAmount - 1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, alice, withdrawAmount, withdrawAmount - 1
            )
        );
        aaveStrategyVault.withdraw(withdrawAmount, alice, alice);

        vm.prank(alice);
        aaveStrategyVault.withdraw(withdrawAmount - 1, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), 0);
        assertEq(aaveStrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), 1);
        assertEq(asset.balanceOf(alice), withdrawAmount - 1);
    }

    function test_AaveStrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e18;
        _mint(asset, bob, donation);
        vm.prank(bob);
        asset.transfer(address(aaveStrategyVault), donation);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.balanceOf(bob), 0);
        assertEq(aaveStrategyVault.totalAssets(), depositAmount + donation);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), depositAmount + donation);

        uint256 previewWithdrawShares = aaveStrategyVault.previewWithdraw(depositAmount + donation);
        assertEq(previewWithdrawShares, shares + 1);

        vm.prank(alice);
        aaveStrategyVault.redeem(shares, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), 0);
        assertEq(aaveStrategyVault.totalAssets(), 1);
        assertEq(asset.balanceOf(address(aaveStrategyVault.aToken())), 1);
        assertEq(asset.balanceOf(alice), depositAmount + donation - 1);
    }
}
