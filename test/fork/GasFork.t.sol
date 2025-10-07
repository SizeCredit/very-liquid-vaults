// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseScript} from "@script/BaseScript.s.sol";

import {Addresses} from "@script/Addresses.s.sol";
import {DEFAULT_ADMIN_ROLE, STRATEGIST_ROLE} from "@src/Auth.sol";
import {IVault} from "@src/IVault.sol";
import {VeryLiquidVault} from "@src/VeryLiquidVault.sol";
import {ForkTest} from "@test/fork/ForkTest.t.sol";
import {console} from "forge-std/console.sol";

contract GasForkTest is ForkTest, Addresses {
    using SafeERC20 for IERC20Metadata;

    VeryLiquidVault public vlv;
    IERC20Metadata public usdc;

    uint256 public amount = 10e6;
    uint256 public bobMaxWithdraw;

    function setUp() public virtual override {
        vm.createSelectFork("base");
        vlv = VeryLiquidVault(addresses[block.chainid][Contract.VeryLiquidVault_Core]);
        usdc = IERC20Metadata(address(vlv.asset()));

        _mint(usdc, alice, amount);
        _approve(alice, usdc, address(vlv), amount);

        _deposit(bob, vlv, amount);
        bobMaxWithdraw = vlv.maxWithdraw(bob);

        IVault[] memory strategies = vlv.strategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            vm.label(address(strategies[i]), strategies[i].symbol());
        }
        vm.label(address(vlv), vlv.symbol());
        vm.label(address(vlv.auth()), "Auth");
        vm.label(address(usdc), usdc.symbol());
        vm.label(address(alice), "Alice");
        vm.label(address(bob), "Bob");

        address owner = vlv.auth().getRoleMember(DEFAULT_ADMIN_ROLE, 0);
        address newImplementation = address(new VeryLiquidVault());

        vm.prank(owner);
        UUPSUpgradeable(address(vlv)).upgradeToAndCall(address(newImplementation), new bytes(0));

        strategist = vlv.auth().getRoleMember(STRATEGIST_ROLE, 0);
        for (uint256 i = 1; i < strategies.length; i++) {
            uint256 maxWithdraw = strategies[i].maxWithdraw(address(vlv));
            if (maxWithdraw == 0) continue;

            vm.prank(strategist);
            vlv.rebalance(strategies[i], strategies[0], maxWithdraw, 0.01e18);
        }
    }

    function testFork_Gas_deposit() public {
        vm.prank(alice);
        vlv.deposit(amount, alice);
    }

    function testFork_Gas_withdraw() public {
        vm.prank(bob);
        vlv.withdraw(bobMaxWithdraw, bob, bob);
    }

    function testFork_Gas_convertToAssets() public view {
        vlv.convertToAssets(amount);
    }

    function testFork_Gas_convertToShares() public view {
        vlv.convertToShares(amount);
    }

    function testFork_Gas_totalAssets() public view {
        vlv.totalAssets();
    }

    function testFork_Gas_totalSupply() public view {
        vlv.totalSupply();
    }
}
