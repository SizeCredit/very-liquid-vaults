// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";

contract BaseStrategyVaultMock is BaseStrategyVault {
    error NotImplemented();

    function pullAssets(address to, uint256 amount) external override {
        revert NotImplemented();
    }
}
