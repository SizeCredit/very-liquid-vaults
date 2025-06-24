// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "@test/BaseTest.t.sol";

contract SizeVaultTest is BaseTest {
    function test_SizeVault_initialize() public view {
        assertEq(address(sizeVault.asset()), address(asset));
        assertEq(sizeVault.name(), string.concat("Size ", asset.name(), " Vault"));
        assertEq(sizeVault.symbol(), string.concat("size", asset.symbol()));
        assertEq(sizeVault.decimals(), asset.decimals());
        assertEq(sizeVault.totalSupply(), 0);
        assertEq(sizeVault.balanceOf(address(this)), 0);
        assertEq(sizeVault.allowance(address(this), address(this)), 0);
        assertEq(sizeVault.decimals(), asset.decimals());
        assertEq(sizeVault.decimals(), asset.decimals());
    }
}
