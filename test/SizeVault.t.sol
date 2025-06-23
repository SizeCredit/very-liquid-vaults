// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {SizeVaultScript} from "@script/SizeVault.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SizeVaultTest is Test {
    SizeVaultScript sizeVaultScript;
    SizeVault sizeVault;
    IERC20Metadata asset;
    address admin;

    function setUp() public {
        asset = IERC20Metadata(address(new ERC20Mock()));
        admin = address(this);

        sizeVaultScript = new SizeVaultScript();
        sizeVault = sizeVaultScript.deploy(asset, admin);
    }

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
