// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

abstract contract PropertiesSpecifications {
    string constant PULL_ASSETS_01 = "PULL_ASSETS_01: transferAssets does not change balanceOf";
    string constant STRATEGY_01 = "STRATEGY_01: Removing a strategy does not change balanceOf";
}
