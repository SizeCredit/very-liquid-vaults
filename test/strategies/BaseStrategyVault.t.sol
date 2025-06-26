// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PAUSER_ROLE} from "@src/SizeVault.sol";

contract BaseStrategyVaultTest is BaseTest {
    function test_BaseStrategyVault_initialize() public view {
        assertEq(address(baseStrategyVault.sizeVault()), address(sizeVault));
        assertEq(baseStrategyVault.asset(), address(sizeVault.asset()));
        assertEq(baseStrategyVault.name(), "Size Base USD Coin Strategy Mock");
        assertEq(baseStrategyVault.symbol(), "sizeBaseUSDCMOCK");
        assertEq(baseStrategyVault.decimals(), asset.decimals(), 6);
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
        newBaseStrategyVault.initialize(SizeVault(address(0)), "Test", "TST");
    }

    function test_BaseStrategyVault_pause_success() public {
        assertFalse(baseStrategyVault.paused());

        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

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
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();
        assertTrue(baseStrategyVault.paused());

        vm.prank(admin);
        baseStrategyVault.unpause();

        assertFalse(baseStrategyVault.paused());
    }

    function test_BaseStrategyVault_unpause_unauthorized_reverts() public {
        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.unpause();
    }

    function test_BaseStrategyVault_deposit_whenPaused_reverts() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(baseStrategyVault), amount);

        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.deposit(amount, alice);
    }

    function test_BaseStrategyVault_deposit_whenSizeVaultPaused_reverts() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(baseStrategyVault), amount);

        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        sizeVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.deposit(amount, alice);
    }

    function test_BaseStrategyVault_transfer_whenPaused_reverts() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(baseStrategyVault), amount);

        vm.prank(alice);
        baseStrategyVault.deposit(amount, alice);

        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        baseStrategyVault.pause();

        vm.prank(alice);
        vm.expectRevert();
        baseStrategyVault.transfer(bob, amount);
    }

    function test_BaseStrategyVault_transfer_whenSizeVaultPaused_reverts() public {
        uint256 amount = 100e18;
        _mint(asset, alice, amount);
        _approve(alice, asset, address(baseStrategyVault), amount);

        vm.prank(alice);
        baseStrategyVault.deposit(amount, alice);

        vm.prank(admin);
        sizeVault.grantRole(PAUSER_ROLE, admin);

        vm.prank(admin);
        sizeVault.pause();

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
        uint256 depositAmount = 100e18;
        _mint(asset, alice, depositAmount);
        _approve(alice, asset, address(baseStrategyVault), depositAmount);

        vm.prank(alice);
        baseStrategyVault.deposit(depositAmount, alice);

        assertEq(baseStrategyVault.balanceOf(alice), depositAmount);
        assertEq(baseStrategyVault.totalAssets(), depositAmount);
        assertEq(asset.balanceOf(address(baseStrategyVault)), depositAmount);
        assertEq(asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e18;
        vm.prank(alice);
        baseStrategyVault.withdraw(withdrawAmount, alice, alice);

        assertEq(baseStrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(baseStrategyVault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(address(baseStrategyVault)), depositAmount - withdrawAmount);
        assertEq(asset.balanceOf(alice), withdrawAmount);
    }
}
