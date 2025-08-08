// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "src/strategies/AaveStrategyVault.sol";
import "src/Auth.sol";
import "src/strategies/CashStrategyVault.sol";
import "src/strategies/ERC4626StrategyVault.sol";
import "src/SizeMetaVault.sol";
import {PropertiesConstants} from "@crytic/properties/contracts/util/PropertiesConstants.sol";

import {Setup as __Setup} from "@test/Setup.t.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils, __Setup, PropertiesConstants {
    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        deploy(address(this));
        _addActor(USER1);
        _addActor(USER2);
        _addActor(USER3);
        _addAsset(address(erc20Asset));
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
    }
}
