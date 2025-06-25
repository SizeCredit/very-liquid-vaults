// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "@test/BaseTest.t.sol";

contract CashStrategyVaultTest is BaseTest {
    function test_CashStrategyVault_deposit() public {
        _mint(asset, alice, 100e18);
        _approve(alice, asset, address(cashStrategyVault), 100e18);
        vm.prank(alice);
        cashStrategyVault.deposit(100e18, alice);
        assertEq(cashStrategyVault.balanceOf(alice), 100e18);
    }
}
