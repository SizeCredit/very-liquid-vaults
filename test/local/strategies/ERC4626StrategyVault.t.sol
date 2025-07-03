// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";

contract ERC4626StrategyVaultTest is BaseTest {
    uint256 initialBalance;
    uint256 initialTotalAssets;

    function setUp() public override {
        super.setUp();
        initialTotalAssets = erc4626StrategyVault.totalAssets();
        initialBalance = erc20Asset.balanceOf(address(erc4626Vault));
    }

    function test_ERC4626StrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), amount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(amount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), amount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + amount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + amount);
        assertEq(erc20Asset.balanceOf(alice), 0);
    }

    function test_ERC4626StrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount);
        assertEq(erc20Asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e6;
        vm.prank(alice);
        erc4626StrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }

    function test_ERC4626StrategyVault_deposit_transferAssets_does_not_change_balanceOf() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e6;
        vm.prank(address(sizeMetaVault));
        erc4626StrategyVault.transferAssets(bob, pullAmount);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(bob), pullAmount);
    }

    function test_ERC4626StrategyVault_deposit_transferAssets_redeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 pullAmount = 30e6;
        vm.prank(address(sizeMetaVault));
        erc4626StrategyVault.transferAssets(bob, pullAmount);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount - pullAmount);
        assertEq(erc20Asset.balanceOf(bob), pullAmount);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);

        vm.prank(alice);
        erc4626StrategyVault.redeem(shares, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }

    function test_ERC4626StrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);

        vm.prank(alice);
        erc4626StrategyVault.withdraw(previewRedeemAssets, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }

    function test_ERC4626StrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);

        vm.prank(alice);
        erc4626StrategyVault.redeem(shares, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }
}
