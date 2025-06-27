// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
import {Setup, Contracts} from "@test/Setup.t.sol";

contract AaveStrategyVaultCryticERC4626Harness is CryticERC4626PropertyTests, Setup {
    constructor() {
        Contracts memory contracts = deploy(address(this));
        initialize(address(contracts.cryticAaveStrategyVault), address(contracts.asset), true);
    }
}
