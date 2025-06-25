// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";

contract BaseStrategyVaultMock is BaseStrategyVault {
    error NotImplemented();

    function pullAssets(address, uint256) external pure override {
        revert NotImplemented();
    }
}
