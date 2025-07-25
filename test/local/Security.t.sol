// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.t.sol";
import {console} from "forge-std/console.sol";

contract SecurityTest is BaseTest {
    function test_Security_deposit_directly_to_strategy_should_not_steal_assets() public {
        address attacker = makeAddr("attacker");

        uint256 depositAmount = 100_000e6; // 100k USDC
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), depositAmount);

        uint256 aliceBalanceBefore = erc20Asset.balanceOf(alice);
        vm.prank(alice);
        sizeMetaVault.deposit(depositAmount, alice);

        _mint(erc20Asset, attacker, depositAmount * 2);
        _approve(attacker, erc20Asset, address(erc4626StrategyVault), depositAmount);
        _approve(attacker, erc20Asset, address(sizeMetaVault), depositAmount);
        uint256 attackerBalanceBefore = erc20Asset.balanceOf(attacker);

        // Perform the 4-step attack
        vm.startPrank(attacker);
        uint256 shares = sizeMetaVault.deposit(depositAmount, attacker); // deposit into metavault at normal share price

        console.log(
            "[before inflating] pricePerShare: %e", sizeMetaVault.totalAssets() * 1e6 / sizeMetaVault.totalSupply()
        );
        erc4626StrategyVault.deposit(depositAmount, attacker); // deposit into underlying strategy to inflate meta vault share price
        console.log(
            "[after inflating] pricePerShare: %e", sizeMetaVault.totalAssets() * 1e6 / sizeMetaVault.totalSupply()
        );

        sizeMetaVault.redeem(shares, attacker, attacker); // redeem meta vault shares at higher share price
        erc4626StrategyVault.withdraw(depositAmount, attacker, attacker); // withdraw from underlying strategy to get back USDC
        console.log("attackerBalance: %e", erc20Asset.balanceOf(attacker));

        console.log("sizeMetaVault.totalAssets(): %e", sizeMetaVault.totalAssets());
        console.log("sizeMetaVault.totalSupply(): %e", sizeMetaVault.totalSupply());

        vm.startPrank(alice);

        sizeMetaVault.redeem(sizeMetaVault.balanceOf(alice), alice, alice);
        uint256 aliceBalanceAfter = erc20Asset.balanceOf(alice);

        assertEq(aliceBalanceBefore, aliceBalanceAfter);
        assertEq(erc20Asset.balanceOf(attacker), attackerBalanceBefore);
        assertEq(sizeMetaVault.balanceOf(alice), 0);
        assertEq(sizeMetaVault.balanceOf(attacker), 0);

        console.log("alice loss: %e", aliceBalanceBefore - aliceBalanceAfter);
        console.log("attacker profit: %e", erc20Asset.balanceOf(attacker) - attackerBalanceBefore);
    }
}
