// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {IAToken} from "@aave/contracts/interfaces/IAToken.sol";

contract AaveStrategyVaultTest is BaseTest {
    uint256 initialBalance;
    uint256 initialTotalAssets;

    function setUp() public override {
        super.setUp();
        initialTotalAssets = aaveStrategyVault.totalAssets();
        initialBalance = erc20Asset.balanceOf(address(aToken));
    }

    function test_AaveStrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), amount);
        vm.prank(alice);
        aaveStrategyVault.deposit(amount, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), amount);
        assertEq(aaveStrategyVault.totalAssets(), initialTotalAssets + amount);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + amount);
        assertEq(erc20Asset.balanceOf(alice), 0);
    }

    function test_AaveStrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), depositAmount);
        assertEq(aaveStrategyVault.totalAssets(), initialTotalAssets + depositAmount);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount);
        assertEq(erc20Asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e6;
        vm.prank(alice);
        aaveStrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(aaveStrategyVault.totalAssets(), initialTotalAssets + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }

    function test_AaveStrategyVault_deposit_transferAssets_does_not_change_balanceOf() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e6;
        vm.prank(address(sizeMetaVault));
        aaveStrategyVault.transferAssets(bob, pullAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.totalAssets(), initialTotalAssets + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(bob), pullAmount);
    }

    function test_AaveStrategyVault_deposit_transferAssets_redeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e6;
        vm.prank(address(sizeMetaVault));
        aaveStrategyVault.transferAssets(bob, pullAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.totalAssets(), initialTotalAssets + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(bob), pullAmount);

        uint256 maxRedeem = aaveStrategyVault.maxRedeem(alice);
        uint256 previewRedeem = aaveStrategyVault.previewRedeem(maxRedeem);

        vm.prank(alice);
        aaveStrategyVault.redeem(maxRedeem, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares - maxRedeem);
        assertEq(erc20Asset.balanceOf(alice), previewRedeem);
    }

    function test_AaveStrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(aToken), donation);
        vm.prank(admin);
        pool.setLiquidityIndex(address(erc20Asset), (depositAmount + donation) * 1e27 / depositAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.balanceOf(bob), 0);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount + donation);

        uint256 maxWithdraw = aaveStrategyVault.maxWithdraw(alice);

        vm.prank(alice);
        aaveStrategyVault.withdraw(maxWithdraw, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), 0);
        assertGe(aaveStrategyVault.totalAssets(), initialTotalAssets);
        assertGe(erc20Asset.balanceOf(address(aToken)), initialBalance);
        assertEq(erc20Asset.balanceOf(alice), maxWithdraw);
    }

    function test_AaveStrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(aaveStrategyVault), depositAmount);
        vm.prank(alice);
        aaveStrategyVault.deposit(depositAmount, alice);
        uint256 shares = aaveStrategyVault.balanceOf(alice);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(aToken), donation);
        vm.prank(admin);
        pool.setLiquidityIndex(address(erc20Asset), (depositAmount + donation) * 1e27 / depositAmount);
        assertEq(aaveStrategyVault.balanceOf(alice), shares);
        assertEq(aaveStrategyVault.balanceOf(bob), 0);
        assertEq(erc20Asset.balanceOf(address(aToken)), initialBalance + depositAmount + donation);

        vm.prank(alice);
        aaveStrategyVault.redeem(shares, alice, alice);
        assertEq(aaveStrategyVault.balanceOf(alice), 0);
        assertGe(aaveStrategyVault.totalAssets(), initialTotalAssets);
        assertGe(erc20Asset.balanceOf(address(aToken)), initialBalance);
    }
}
