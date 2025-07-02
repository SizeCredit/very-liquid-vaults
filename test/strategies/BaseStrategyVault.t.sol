// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PAUSER_ROLE, DEFAULT_ADMIN_ROLE} from "@src/Auth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseStrategyVaultTest is BaseTest {
    function test_BaseStrategyVault_initialize() public view {
        assertEq(address(baseStrategyVault.sizeVault()), address(sizeVault));
        assertEq(baseStrategyVault.asset(), address(sizeVault.asset()));
        assertEq(baseStrategyVault.name(), "Size Base USD Coin Strategy Mock");
        assertEq(baseStrategyVault.symbol(), "sizeBaseUSDCMOCK");
        assertEq(baseStrategyVault.decimals(), erc20Asset.decimals(), 6);
    }

    function test_BaseStrategyVault_upgrade() public {
        BaseStrategyVaultMock newBaseStrategyVault = new BaseStrategyVaultMock();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        UUPSUpgradeable(address(baseStrategyVault)).upgradeToAndCall(address(newBaseStrategyVault), "");

        vm.prank(admin);
        UUPSUpgradeable(address(baseStrategyVault)).upgradeToAndCall(address(newBaseStrategyVault), "");
    }

    function test_BaseStrategyVault_initialize_invalidInitialization_reverts() public {
        BaseStrategyVaultMock newBaseStrategyVault = new BaseStrategyVaultMock();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        newBaseStrategyVault.initialize(auth, IERC20(address(0)), "Test", "TST", FIRST_DEPOSIT_AMOUNT);
    }

    function test_BaseStrategyVault_pause_success() public {
        assertFalse(baseStrategyVault.paused());

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        assertTrue(baseStrategyVault.paused());
    }

    function test_BaseStrategyVault_pause_unauthorized_reverts() public {
        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.pause();
    }

    function test_BaseStrategyVault_unpause_success() public {
        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();
        assertTrue(baseStrategyVault.paused());

        vm.prank(admin);
        baseStrategyVault.unpause();

        assertFalse(baseStrategyVault.paused());
    }

    function test_BaseStrategyVault_unpause_unauthorized_reverts() public {
        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.unpause();
    }

    function test_BaseStrategyVault_deposit_whenPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseStrategyVault), amount);

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.deposit(amount, alice);
    }

    function test_BaseStrategyVault_deposit_whenAuthPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseStrategyVault), amount);

        vm.prank(admin);
        auth.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.deposit(amount, alice);
    }

    function test_BaseStrategyVault_transfer_whenPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseStrategyVault), amount);

        vm.prank(alice);
        baseStrategyVault.deposit(amount, alice);

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.transfer(bob, amount);
    }

    function test_BaseStrategyVault_transfer_whenAuthPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseStrategyVault), amount);

        vm.prank(alice);
        baseStrategyVault.deposit(amount, alice);

        vm.prank(admin);
        auth.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.transfer(bob, amount);
    }

    function test_BaseStrategyVault_onlySizeVault_modifier_success() public {
        vm.prank(address(sizeVault));
        vm.expectRevert(BaseStrategyVaultMock.NotImplemented.selector);
        baseStrategyVault.pullAssets(bob, 100e18);
    }

    function test_BaseStrategyVault_deposit_withdraw_basic() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(baseStrategyVault), depositAmount);

        vm.prank(alice);
        baseStrategyVault.deposit(depositAmount, alice);

        assertEq(baseStrategyVault.balanceOf(alice), depositAmount);
        assertEq(baseStrategyVault.totalAssets(), FIRST_DEPOSIT_AMOUNT + depositAmount);
        assertEq(erc20Asset.balanceOf(address(baseStrategyVault)), FIRST_DEPOSIT_AMOUNT + depositAmount);
        assertEq(erc20Asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e6;
        vm.prank(alice);
        baseStrategyVault.withdraw(withdrawAmount, alice, alice);

        assertEq(baseStrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(baseStrategyVault.totalAssets(), FIRST_DEPOSIT_AMOUNT + depositAmount - withdrawAmount);
        assertEq(
            erc20Asset.balanceOf(address(baseStrategyVault)), FIRST_DEPOSIT_AMOUNT + depositAmount - withdrawAmount
        );
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }
}
