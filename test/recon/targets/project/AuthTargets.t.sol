// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Ghosts} from "@test/recon/Ghosts.t.sol";
import {Properties} from "@test/recon/Properties.t.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Auth.sol";

abstract contract AuthTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function auth_pause() public asActor {
        auth.pause();
    }

    function auth_unpause() public asActor {
        auth.unpause();
    }
}
