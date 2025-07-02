// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
import {Setup} from "@test/Setup.t.sol";

contract SizeVaultCryticERC4626Harness is CryticERC4626PropertyTests, Setup {
    constructor() {
        deploy(address(this));
        initialize(address(sizeVault), address(asset), true);
    }
}
