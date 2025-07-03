// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

abstract contract PropertiesSpecifications {
    string constant REBALANCE_01 = "REBALANCE_01: rebalance does not change balanceOf";
    string constant TRANSFER_ASSETS_01 = "TRANSFER_ASSETS_01: transferAssets does not change balanceOf";
    string constant STRATEGY_01 = "STRATEGY_01: Removing a strategy does not change balanceOf";
}
