// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Ghosts} from "@test/recon/Ghosts.sol";
import {Properties} from "@test/recon/Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/SizeMetaVault.sol";

abstract contract SizeMetaVaultTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function sizeMetaVault_addStrategy(IVault strategy_) public asActor {
        sizeMetaVault.addStrategy(strategy_);
    }

    function sizeMetaVault_approve(address spender, uint256 value) public asActor {
        sizeMetaVault.approve(spender, value);
    }

    function sizeMetaVault_deposit(uint256 assets, address receiver) public asActor {
        sizeMetaVault.deposit(assets, receiver);
    }

    function sizeMetaVault_mint(uint256 shares, address receiver) public asActor {
        sizeMetaVault.mint(shares, receiver);
    }

    function sizeMetaVault_pause() public asActor {
        sizeMetaVault.pause();
    }

    function sizeMetaVault_rebalance(IVault strategyFrom, IVault strategyTo, uint256 amount, uint256 maxSlippagePercent)
        public
        asActor
    {
        sizeMetaVault.rebalance(strategyFrom, strategyTo, amount, maxSlippagePercent);
    }

    function sizeMetaVault_redeem(uint256 shares, address receiver, address owner) public asActor {
        sizeMetaVault.redeem(shares, receiver, owner);
    }

    function sizeMetaVault_removeStrategy(
        IVault strategyToRemove,
        IVault strategyToReceiveAssets,
        uint256 amount,
        uint256 maxSlippagePercent
    ) public asActor {
        sizeMetaVault.removeStrategy(strategyToRemove, strategyToReceiveAssets, amount, maxSlippagePercent);
    }

    function sizeMetaVault_reorderStrategies(IVault[] memory newStrategiesOrder) public asActor {
        sizeMetaVault.reorderStrategies(newStrategiesOrder);
    }

    function sizeMetaVault_setFeeRecipient(address feeRecipient_) public asActor {
        sizeMetaVault.setFeeRecipient(feeRecipient_);
    }

    function sizeMetaVault_setPerformanceFeePercent(uint256 performanceFeePercent_) public asActor {
        sizeMetaVault.setPerformanceFeePercent(performanceFeePercent_);
    }

    function sizeMetaVault_setRebalanceMaxSlippagePercent(uint256 rebalanceMaxSlippagePercent_) public asActor {
        sizeMetaVault.setRebalanceMaxSlippagePercent(rebalanceMaxSlippagePercent_);
    }

    function sizeMetaVault_setTotalAssetsCap(uint256 totalAssetsCap_) public asActor {
        sizeMetaVault.setTotalAssetsCap(totalAssetsCap_);
    }

    function sizeMetaVault_transfer(address to, uint256 value) public asActor {
        sizeMetaVault.transfer(to, value);
    }

    function sizeMetaVault_transferFrom(address from, address to, uint256 value) public asActor {
        sizeMetaVault.transferFrom(from, to, value);
    }

    function sizeMetaVault_unpause() public asActor {
        sizeMetaVault.unpause();
    }

    function sizeMetaVault_withdraw(uint256 assets, address receiver, address owner) public asActor {
        sizeMetaVault.withdraw(assets, receiver, owner);
    }
}
