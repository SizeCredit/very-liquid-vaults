// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
import {Setup} from "@test/Setup.t.sol";
import {hevm} from "@crytic/properties/contracts/util/Hevm.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";

contract SizeMetaVaultCryticERC4626Harness is CryticERC4626PropertyTests, Setup {
    constructor() {
        deploy(address(this));
        initialize(address(sizeMetaVault), address(asset), true);
    }

    function rebalance(address strategyFrom, address strategyTo, uint256 amount, uint256 minAmount) public {
        hevm.prank(address(this));
        sizeMetaVault.rebalance(IStrategy(strategyFrom), IStrategy(strategyTo), amount, minAmount);
    }
}
