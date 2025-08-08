// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {IVault} from "@src/utils/IVault.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }

    // forge test --match-test test_crytic -vvv
    function test_CryticToFoundry_01() public {
        sizeMetaVault_addStrategy(cryticSizeMetaVault);
        try this.sizeMetaVault_removeStrategy(
            cashStrategyVault,
            cryticSizeMetaVault,
            0,
            12309285055488365505482212365492300592776939712510733309382679362574362184841
        ) {
            erc4626_mustNotRevert_previewWithdraw(
                2225540755836731568673543958881982534501949212283136249702905096594965025
            );
        } catch (bytes memory err) {
            assertEq(err, abi.encodeWithSelector(BaseVault.NullAmount.selector));
        }
    }
}
