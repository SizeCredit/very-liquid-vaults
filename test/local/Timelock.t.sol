// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Timelock} from "@src/utils/Timelock.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/utils/Auth.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";

contract TimelockTest is BaseTest {
    function test_Timelock_initialize() public view {
        assertGt(sizeMetaVault.timelockDurations(sizeMetaVault.addStrategies.selector), 0);
        assertGt(sizeMetaVault.timelockDurations(sizeMetaVault.removeStrategies.selector), 0);
        assertEq(sizeMetaVault.timelockDurations(sizeMetaVault.rebalance.selector), 0);
    }

    function test_Timelock_setTimelockDuration_auth() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE
            )
        );
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategies.selector, 30 days);

        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategies.selector, 30 days);
    }

    function test_Timelock_timelocked_twice_different_data() public {
        vm.warp(15 minutes);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = aaveStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 15 minutes);

        vm.warp(30 minutes);

        IStrategy[] memory strategies2 = new IStrategy[](1);
        strategies2[0] = cashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies2);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 30 minutes);
    }

    function test_Timelock_timelocked_twice_same_data() public {
        vm.warp(123 days);

        assertTrue(!sizeMetaVault.isTimelocked(sizeMetaVault.addStrategies.selector));

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = aaveStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 123 days);
        assertTrue(sizeMetaVault.isTimelocked(sizeMetaVault.addStrategies.selector));

        vm.warp(block.timestamp + 42 seconds);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 123 days);
    }

    function test_Timelock_timelocked_is_bypassed_by_admin() public {
        vm.warp(123 days);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = cryticAaveStrategyVault;

        vm.prank(admin);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);
        assertEq(sizeMetaVault.isTimelocked(sizeMetaVault.addStrategies.selector), false);

        vm.prank(admin);
        sizeMetaVault.removeStrategies(strategies, cashStrategyVault);

        assertEq(sizeMetaVault.isTimelocked(sizeMetaVault.removeStrategies.selector), false);
    }

    function test_Timelock_timelocked_is_reset_after_execution() public {
        vm.warp(123 days);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = cryticAaveStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 123 days);

        uint256 timelockDuration = sizeMetaVault.timelockDurations(sizeMetaVault.addStrategies.selector);

        vm.warp(timelockDuration + proposedTimestamp);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);

        vm.warp(1000 days);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 1000 days);
    }

    function test_Timelock_setTimelockDuration_invalid_duration() public {
        uint256 minimumDuration = sizeMetaVault.MINIMUM_TIMELOCK_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(
                Timelock.TimelockDurationTooShort.selector, sizeMetaVault.addStrategies.selector, 0, minimumDuration
            )
        );
        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategies.selector, 0);

        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategies.selector, minimumDuration);
        assertEq(sizeMetaVault.timelockDurations(sizeMetaVault.addStrategies.selector), minimumDuration);
    }

    function test_Timelock_multicall() public {
        vm.warp(123 days);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = cryticCashStrategyVault;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(sizeMetaVault.addStrategies, (strategies));
        data[1] = abi.encodeCall(sizeMetaVault.rebalance, (cashStrategyVault, aaveStrategyVault, 5e6, 0));

        vm.prank(strategist);
        sizeMetaVault.multicall(data);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 123 days);

        uint256 timelockDuration = sizeMetaVault.timelockDurations(sizeMetaVault.addStrategies.selector);

        vm.warp(timelockDuration + proposedTimestamp);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategies.selector);
        assertEq(proposedTimestamp, 0);
    }
}
