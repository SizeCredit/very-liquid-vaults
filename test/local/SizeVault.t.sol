// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.t.sol";

contract SizeVaultTest is BaseTest {
    function test_SizeVault_initialize() public view {
        assertEq(address(sizeVault.asset()), address(erc20Asset));
        assertEq(sizeVault.name(), string.concat("Size ", erc20Asset.name(), " Vault"));
        assertEq(sizeVault.symbol(), string.concat("size", erc20Asset.symbol()));
        assertEq(sizeVault.decimals(), erc20Asset.decimals());
        assertEq(sizeVault.totalSupply(), sizeVault.strategiesCount() * FIRST_DEPOSIT_AMOUNT + 1);
        assertEq(sizeVault.balanceOf(address(this)), 0);
        assertEq(sizeVault.allowance(address(this), address(this)), 0);
        assertEq(sizeVault.decimals(), erc20Asset.decimals());
        assertEq(sizeVault.decimals(), erc20Asset.decimals());
    }
}
