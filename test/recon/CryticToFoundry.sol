// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {IVault} from "@src/utils/IVault.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        sizeMetaVault_removeStrategy(IVault(0x6889d1378a04A5DA6a4e0F846c848B9ddB58C518), IVault(0xfFAc0F4F99659190D196232d28798e36ffE3336c), 0, 3598280323797073438562738483381227096788826338843307699337716344421460076096);
        erc4626_convertToShares(55435129753960307879381427661303100766667599429958680309323665825220199478310);
    }
}
