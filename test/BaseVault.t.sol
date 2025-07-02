// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {BaseVaultMock} from "@test/mocks/BaseVaultMock.t.sol";
import {PAUSER_ROLE, DEFAULT_ADMIN_ROLE} from "@src/Auth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseVaultTest is BaseTest {
    function test_BaseVault_initialize() public view {
        assertEq(baseVaultMock.asset(), address(erc20Asset));
        assertEq(baseVaultMock.name(), "Base USD Coin Mock");
        assertEq(baseVaultMock.symbol(), "baseUSDCMOCK");
        assertEq(baseVaultMock.decimals(), erc20Asset.decimals(), 6);
    }

    function test_BaseVault_upgrade() public {
        BaseVaultMock newBaseVault = new BaseVaultMock();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        UUPSUpgradeable(address(baseVaultMock)).upgradeToAndCall(address(newBaseVault), "");

        vm.prank(admin);
        UUPSUpgradeable(address(baseVaultMock)).upgradeToAndCall(address(newBaseVault), "");
    }

    function test_BaseVault_initialize_invalidInitialization_reverts() public {
        BaseVaultMock newBaseVault = new BaseVaultMock();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        newBaseVault.initialize(auth, IERC20(address(0)), "Test", "TST", FIRST_DEPOSIT_AMOUNT);
    }

    function test_BaseVault_pause_success() public {
        assertFalse(baseVaultMock.paused());

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseVaultMock.pause();

        assertTrue(baseVaultMock.paused());
    }

    function test_BaseVault_pause_unauthorized_reverts() public {
        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.pause();
    }

    function test_BaseVault_unpause_success() public {
        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseVaultMock.pause();
        assertTrue(baseVaultMock.paused());

        vm.prank(admin);
        baseVaultMock.unpause();

        assertFalse(baseVaultMock.paused());
    }

    function test_BaseVault_unpause_unauthorized_reverts() public {
        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseVaultMock.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.unpause();
    }

    function test_BaseVault_deposit_whenPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseVaultMock), amount);

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseVaultMock.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.deposit(amount, alice);
    }

    function test_BaseVault_deposit_whenAuthPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseVaultMock), amount);

        vm.prank(admin);
        auth.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.deposit(amount, alice);
    }

    function test_BaseVault_transfer_whenPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseVaultMock), amount);

        vm.prank(alice);
        baseVaultMock.deposit(amount, alice);

        vm.prank(admin);
        auth.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseVaultMock.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.transfer(bob, amount);
    }

    function test_BaseVault_transfer_whenAuthPaused_reverts() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(baseVaultMock), amount);

        vm.prank(alice);
        baseVaultMock.deposit(amount, alice);

        vm.prank(admin);
        auth.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseVaultMock.transfer(bob, amount);
    }

    function test_BaseVault_deposit_withdraw_basic() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(baseVaultMock), depositAmount);

        vm.prank(alice);
        baseVaultMock.deposit(depositAmount, alice);

        assertEq(baseVaultMock.balanceOf(alice), depositAmount);
        assertEq(baseVaultMock.totalAssets(), FIRST_DEPOSIT_AMOUNT + depositAmount);
        assertEq(erc20Asset.balanceOf(address(baseVaultMock)), FIRST_DEPOSIT_AMOUNT + depositAmount);
        assertEq(erc20Asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e6;
        vm.prank(alice);
        baseVaultMock.withdraw(withdrawAmount, alice, alice);

        assertEq(baseVaultMock.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(baseVaultMock.totalAssets(), FIRST_DEPOSIT_AMOUNT + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(address(baseVaultMock)), FIRST_DEPOSIT_AMOUNT + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }
}
