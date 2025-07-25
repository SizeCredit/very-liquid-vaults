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

    function test_Security_setting_fee_later_should_not_steal_from_existing_depositors() public {
        // Alice deposits 6e7
        _deposit(alice, sizeMetaVault, 6e7);

        // Log admin shares before setting the fee
        uint256 sharesBefore = sizeMetaVault.balanceOf(admin);
        console.log("Admin shares before: %e", sharesBefore);

        // Set performance fee of 10%
        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.1e18);

        uint256 setPerformanceFeePercentTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.setPerformanceFeePercent.selector).duration;
        vm.warp(block.timestamp + setPerformanceFeePercentTimelockDuration);

        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.1e18);

        // Alice deposits 1 wei
        _deposit(alice, sizeMetaVault, 1);

        // Log admin shares after setting the fee
        uint256 sharesAfter = sizeMetaVault.balanceOf(admin);
        console.log("Admin shares after: %e", sharesAfter);

        // Assert that the admin was minted shares
        // Even though the vault has not generated any profit, the admin SHOULD NOT get a portion of existing deposits
        assertEq(sharesAfter, sharesBefore);
    }
}
