// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "@test/BaseTest.t.sol";

contract CashStrategyTest is BaseTest {
    function test_CashStrategy_deposit() public {
        _mint(asset, alice, 100e18);
        _approve(alice, asset, address(cashStrategy), 100e18);
        vm.prank(alice);
        cashStrategy.deposit(100e18, alice);
        assertEq(cashStrategy.balanceOf(alice), 100e18);
    }
}
