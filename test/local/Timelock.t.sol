// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Timelock} from "@src/Timelock.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/Auth.sol";

contract TimelockTest is BaseTest {
    function test_Timelock_initialize() public view {
        assertGt(sizeMetaVault.timelockDurations(sizeMetaVault.addStrategy.selector), 0);
        assertGt(sizeMetaVault.timelockDurations(sizeMetaVault.removeStrategy.selector), 0);
        assertEq(sizeMetaVault.timelockDurations(sizeMetaVault.rebalance.selector), 0);
    }

    function test_Timelock_setTimelockDuration_auth() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE
            )
        );
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategy.selector, 30 days);

        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategy.selector, 30 days);
    }

    function test_Timelock_checkTimelock_twice_different_data() public {
        vm.warp(15 minutes);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 0);

        vm.prank(strategist);
        sizeMetaVault.addStrategy(aaveStrategyVault);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 15 minutes);

        vm.warp(30 minutes);

        vm.prank(strategist);
        sizeMetaVault.addStrategy(cashStrategyVault);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 30 minutes);
    }

    function test_Timelock_checkTimelock_twice_same_data() public {
        vm.warp(123 days);

        uint256 proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 0);

        vm.prank(strategist);
        sizeMetaVault.addStrategy(aaveStrategyVault);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 123 days);

        vm.warp(block.timestamp + 42 seconds);

        vm.prank(strategist);
        sizeMetaVault.addStrategy(aaveStrategyVault);

        proposedTimestamp = sizeMetaVault.proposedTimestamps(sizeMetaVault.addStrategy.selector);
        assertEq(proposedTimestamp, 123 days);
    }

    function test_Timelock_setTimelockDuration_invalid_duration() public {
        uint256 minimumDuration = sizeMetaVault.MINIMUM_TIMELOCK_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(
                Timelock.TimelockDurationTooShort.selector, sizeMetaVault.addStrategy.selector, 0, minimumDuration
            )
        );
        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategy.selector, 0);

        vm.prank(admin);
        sizeMetaVault.setTimelockDuration(sizeMetaVault.addStrategy.selector, minimumDuration);
        assertEq(sizeMetaVault.timelockDurations(sizeMetaVault.addStrategy.selector), minimumDuration);
    }
}
