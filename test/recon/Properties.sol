// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {Ghosts} from "./Ghosts.sol";
import {PropertiesSpecifications} from "@test/property/PropertiesSpecifications.t.sol";

abstract contract Properties is Ghosts, Asserts, PropertiesSpecifications {
    function property_SOLVENCY_01() public {
        address[] memory actors = _getActors();
        uint256 assets = 0;
        for (uint256 i = 0; i < actors.length; i++) {
            address actor = actors[i];
            uint256 balanceOf = erc20Asset.balanceOf(actor);
            assets += sizeMetaVault.convertToAssets(balanceOf);
        }
        lte(assets, sizeMetaVault.totalAssets(), SOLVENCY_01);
    }
}
