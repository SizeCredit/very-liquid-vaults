// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {PerformanceVault} from "@src/PerformanceVault.sol";

contract PerformanceVaultTest is BaseTest {
    function test_PerformanceVault_initialize() public view {
        assertEq(sizeMetaVault.feeRecipient(), admin);
        assertEq(sizeMetaVault.performanceFeePercent(), 0);
        assertEq(sizeMetaVault.highWaterMark(), 0);
    }

    function test_PerformanceVault_setPerformanceFeePercent() public {
        assertEq(sizeMetaVault.performanceFeePercent(), 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE
            )
        );
        sizeMetaVault.setPerformanceFeePercent(0.2e18);

        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.7e19);

        uint256 setPerformanceFeePercentTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.setPerformanceFeePercent.selector).duration;
        vm.warp(block.timestamp + setPerformanceFeePercentTimelockDuration);

        uint256 maxPerformanceFeePercent = sizeMetaVault.MAXIMUM_PERFORMANCE_FEE_PERCENT();

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                PerformanceVault.PerformanceFeePercentTooHigh.selector, 0.7e19, maxPerformanceFeePercent
            )
        );
        sizeMetaVault.setPerformanceFeePercent(0.7e19);

        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.2e18);

        vm.warp(block.timestamp + setPerformanceFeePercentTimelockDuration);

        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.2e18);

        assertEq(sizeMetaVault.performanceFeePercent(), 0.2e18);
    }

    function test_PerformanceVault_setFeeRecipient() public {
        assertEq(sizeMetaVault.feeRecipient(), admin);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE
            )
        );
        sizeMetaVault.setFeeRecipient(alice);

        vm.prank(admin);
        sizeMetaVault.setFeeRecipient(alice);

        assertEq(sizeMetaVault.feeRecipient(), alice);
    }

    function test_PerformanceVault_performace_fee_is_minted_as_shares_to_the_feeRecipient() public {
        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.2e18);

        uint256 setPerformanceFeePercentTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.setPerformanceFeePercent.selector).duration;
        vm.warp(block.timestamp + setPerformanceFeePercentTimelockDuration);

        vm.prank(admin);
        sizeMetaVault.setPerformanceFeePercent(0.2e18);

        _deposit(alice, sizeMetaVault, 100e6);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, aaveStrategyVault, 100e6, 0);

        _mint(erc20Asset, address(cashStrategyVault), 300e6);
        _deposit(alice, sizeMetaVault, 200e6);

        uint256 sharesBefore = sizeMetaVault.balanceOf(admin);

        _withdraw(alice, sizeMetaVault, 50e6);

        uint256 sharesAfter = sizeMetaVault.balanceOf(admin);
        assertGt(sharesAfter, sharesBefore);
    }
}
