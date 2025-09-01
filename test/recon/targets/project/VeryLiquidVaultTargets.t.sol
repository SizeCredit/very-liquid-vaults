// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Ghosts} from "@test/recon/Ghosts.t.sol";
import {Properties} from "@test/recon/Properties.t.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/VeryLiquidVault.sol";

abstract contract VeryLiquidVaultTargets is BaseTargetFunctions, Properties {
  /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

  /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

  function veryLiquidVault_addStrategy(IVault strategy_) public asActor {
    veryLiquidVault.addStrategy(strategy_);
  }

  function veryLiquidVault_approve(address spender, uint256 value) public asActor {
    veryLiquidVault.approve(spender, value);
  }

  function veryLiquidVault_deposit(uint256 assets, address receiver) public asActor {
    veryLiquidVault.deposit(assets, receiver);

    if (assets > 0) lte(veryLiquidVault.totalAssets(), veryLiquidVault.totalAssetsCap(), TOTAL_ASSETS_CAP_01);
  }

  function veryLiquidVault_mint(uint256 shares, address receiver) public asActor {
    veryLiquidVault.mint(shares, receiver);

    if (shares > 0) lte(veryLiquidVault.totalAssets(), veryLiquidVault.totalAssetsCap(), TOTAL_ASSETS_CAP_01);
  }

  function veryLiquidVault_pause() public asActor {
    veryLiquidVault.pause();
  }

  function veryLiquidVault_rebalance(IVault strategyFrom, IVault strategyTo, uint256 amount, uint256 maxSlippagePercent) public asActor {
    address[] memory actors = _getActors();
    uint256[] memory balancesBefore = new uint256[](actors.length);
    uint256[] memory convertToAssetsBefore = new uint256[](actors.length);
    for (uint256 i = 0; i < actors.length; i++) {
      address actor = actors[i];
      balancesBefore[i] = veryLiquidVault.balanceOf(actor);
      convertToAssetsBefore[i] = veryLiquidVault.convertToAssets(balancesBefore[i]);
    }

    veryLiquidVault.rebalance(strategyFrom, strategyTo, amount, maxSlippagePercent);

    for (uint256 i = 0; i < actors.length; i++) {
      address actor = actors[i];
      uint256 balanceOf = veryLiquidVault.balanceOf(actor);
      uint256 convertToAssets = veryLiquidVault.convertToAssets(balanceOf);
      eq(balanceOf, balancesBefore[i], REBALANCE_01);
      eq(convertToAssets, convertToAssetsBefore[i], REBALANCE_02);
    }
  }

  function veryLiquidVault_redeem(uint256 shares, address receiver, address owner) public asActor {
    veryLiquidVault.redeem(shares, receiver, owner);
  }

  function veryLiquidVault_removeStrategy(IVault strategyToRemove, IVault strategyToReceiveAssets, uint256 amount, uint256 maxSlippagePercent) public asActor {
    address[] memory actors = _getActors();
    uint256[] memory balancesBefore = new uint256[](actors.length);
    for (uint256 i = 0; i < actors.length; i++) {
      address actor = actors[i];
      balancesBefore[i] = veryLiquidVault.balanceOf(actor);
    }

    veryLiquidVault.removeStrategy(strategyToRemove, strategyToReceiveAssets, amount, maxSlippagePercent);

    for (uint256 i = 0; i < actors.length; i++) {
      address actor = actors[i];
      uint256 balanceOf = veryLiquidVault.balanceOf(actor);
      eq(balanceOf, balancesBefore[i], STRATEGY_01);
    }
  }

  function veryLiquidVault_reorderStrategies(IVault[] memory newStrategiesOrder) public asActor {
    veryLiquidVault.reorderStrategies(newStrategiesOrder);
  }

  function veryLiquidVault_setFeeRecipient(address feeRecipient_) public asActor {
    veryLiquidVault.setFeeRecipient(feeRecipient_);
  }

  function veryLiquidVault_setPerformanceFeePercent(uint256 performanceFeePercent_) public asActor {
    veryLiquidVault.setPerformanceFeePercent(performanceFeePercent_);
  }

  function veryLiquidVault_setRebalanceMaxSlippagePercent(uint256 rebalanceMaxSlippagePercent_) public asActor {
    veryLiquidVault.setRebalanceMaxSlippagePercent(rebalanceMaxSlippagePercent_);
  }

  function veryLiquidVault_setTotalAssetsCap(uint256 totalAssetsCap_) public asActor {
    if (totalAssetsCap_ != type(uint128).max) totalAssetsCap_ = between(totalAssetsCap_, 0, type(uint128).max);
    veryLiquidVault.setTotalAssetsCap(totalAssetsCap_);
  }

  function veryLiquidVault_transfer(address to, uint256 value) public asActor {
    veryLiquidVault.transfer(to, value);
  }

  function veryLiquidVault_transferFrom(address from, address to, uint256 value) public asActor {
    veryLiquidVault.transferFrom(from, to, value);
  }

  function veryLiquidVault_unpause() public asActor {
    veryLiquidVault.unpause();
  }

  function veryLiquidVault_withdraw(uint256 assets, address receiver, address owner) public asActor {
    veryLiquidVault.withdraw(assets, receiver, owner);
  }
}
