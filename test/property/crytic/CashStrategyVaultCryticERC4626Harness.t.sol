// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
import {Setup} from "@test/Setup.t.sol";

contract CashStrategyVaultCryticERC4626Harness is CryticERC4626PropertyTests, Setup {
    constructor() {
        deploy(address(this));
        require(address(erc20Asset) != address(0));
        initialize(address(cryticCashStrategyVault), address(erc20Asset), true);
    }
}
