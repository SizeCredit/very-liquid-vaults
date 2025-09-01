// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {BaseVault} from "@src/utils/BaseVault.sol";
import {PerformanceVault} from "@src/utils/PerformanceVault.sol";
import {BaseTest} from "@test/BaseTest.t.sol";

contract PerformanceVaultTest is BaseTest {
  function test_PerformanceVault_initialize() public view {
    assertEq(veryLiquidVault.feeRecipient(), admin);
    assertEq(veryLiquidVault.performanceFeePercent(), 0);
    assertEq(veryLiquidVault.highWaterMark(), 0);
  }

  function test_PerformanceVault_setPerformanceFeePercent() public {
    assertEq(veryLiquidVault.performanceFeePercent(), 0);

    vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE));
    veryLiquidVault.setPerformanceFeePercent(0.2e18);

    uint256 maxPerformanceFeePercent = veryLiquidVault.MAXIMUM_PERFORMANCE_FEE_PERCENT();

    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSelector(PerformanceVault.PerformanceFeePercentTooHigh.selector, 0.7e19, maxPerformanceFeePercent));
    veryLiquidVault.setPerformanceFeePercent(0.7e19);

    vm.prank(admin);
    veryLiquidVault.setPerformanceFeePercent(0.2e18);

    assertEq(veryLiquidVault.performanceFeePercent(), 0.2e18);
  }

  function test_PerformanceVault_setFeeRecipient() public {
    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
    veryLiquidVault.setFeeRecipient(address(0));

    assertEq(veryLiquidVault.feeRecipient(), admin);

    vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), DEFAULT_ADMIN_ROLE));
    veryLiquidVault.setFeeRecipient(alice);

    vm.prank(admin);
    veryLiquidVault.setFeeRecipient(alice);

    assertEq(veryLiquidVault.feeRecipient(), alice);
  }

  function test_PerformanceVault_performace_fee_is_minted_as_shares_to_the_feeRecipient() public {
    _setupSimpleConfiguration();

    vm.prank(admin);
    veryLiquidVault.setPerformanceFeePercent(0.2e18);

    _deposit(alice, veryLiquidVault, 100e6);

    uint256 sharesBefore = veryLiquidVault.balanceOf(admin);

    _mint(erc20Asset, address(cashStrategyVault), 300e6);
    _deposit(alice, veryLiquidVault, 70e6);

    uint256 sharesAfter = veryLiquidVault.balanceOf(admin);

    assertGt(sharesAfter, sharesBefore);

    _deposit(alice, veryLiquidVault, 40e6);

    uint256 sharesFinal = veryLiquidVault.balanceOf(admin);
    assertEq(sharesFinal, sharesAfter);
  }

  function test_PerformanceVault_highWaterMark_check() public {
    vm.prank(admin);
    veryLiquidVault.setPerformanceFeePercent(0.2e18);
    _deposit(alice, veryLiquidVault, 100e6);
    _mint(erc20Asset, address(cashStrategyVault), 300e6);
    assertEq(veryLiquidVault.highWaterMark(), 1e18);
    _deposit(alice, veryLiquidVault, 0);
    assertEq(veryLiquidVault.highWaterMark(), veryLiquidVault.pps());
  }
}
