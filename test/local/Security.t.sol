// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.t.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {console} from "forge-std/console.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

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

        // Alice deposits 1 wei
        _deposit(alice, sizeMetaVault, 1);

        // Log admin shares after setting the fee
        uint256 sharesAfter = sizeMetaVault.balanceOf(admin);
        console.log("Admin shares after: %e", sharesAfter);

        // Assert that the admin was minted shares
        // Even though the vault has not generated any profit, the admin SHOULD NOT get a portion of existing deposits
        assertEq(sharesAfter, sharesBefore);
    }

    function test_Security_fee_minting_uses_correct_share_conversion() public {
        vm.prank(admin);
        sizeMetaVault.removeStrategy(erc4626StrategyVault, cashStrategyVault, type(uint256).max, 0);
        vm.prank(admin);
        sizeMetaVault.removeStrategy(aaveStrategyVault, cashStrategyVault, type(uint256).max, 0);

        uint256 totalAssets = sizeMetaVault.totalAssets();

        // 1. Set performance fee to 20%
        uint256 feePercent = 0.2e18;
        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(feePercent);

        // 2. Deposit 100 USDC from Alice => initial PPS = 1.0
        _deposit(alice, sizeMetaVault, totalAssets);
        assertEq(Math.mulDiv(sizeMetaVault.totalAssets(), 1e18, sizeMetaVault.totalSupply()), 1e18, "PPS should be 1");

        // 3. Simulate vault profit: 100% profit to the strategy
        uint256 profit = cashStrategyVault.totalAssets() + 1;
        _mint(erc20Asset, address(charlie), profit);
        vm.prank(charlie);
        erc20Asset.transfer(address(cashStrategyVault), profit);
        assertEq(Math.mulDiv(sizeMetaVault.totalAssets(), 1e18, sizeMetaVault.totalSupply()), 2e18, "PPS should be 2");

        assertEq(sizeMetaVault.balanceOf(admin), 0, "Admin should not have any shares");

        console.log("totalSupplyBefore", sizeMetaVault.totalSupply());
        console.log("totalAssetsBefore", sizeMetaVault.totalAssets());
        console.log("balanceOf(alice)", sizeMetaVault.balanceOf(alice));

        uint256 totalSupplyBefore = sizeMetaVault.totalSupply();
        uint256 balance = sizeMetaVault.maxWithdraw(alice);
        _withdraw(alice, sizeMetaVault, balance);

        console.log("totalSupplyAfter", sizeMetaVault.totalSupply());
        console.log("totalAssetsAfter", sizeMetaVault.totalAssets());
        console.log("balanceOf(alice)", sizeMetaVault.balanceOf(alice));

        // 5. Compute expected fee shares
        uint256 expectedFeeShares = totalSupplyBefore / 10 / 2;

        uint256 actualFeeShares = sizeMetaVault.balanceOf(admin);
        assertEq(actualFeeShares, expectedFeeShares, "Fee shares minted incorrectly");
    }
}
