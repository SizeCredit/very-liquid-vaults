// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

abstract contract PropertiesSpecifications {
    string constant RT_01 = "RT_01: Any two operations should not change convertToAssets(balanceOf) other users";
    string constant SOLVENCY_01 = "SOLVENCY_01: SUM(convertToAssets(balanceOf)) <= totalAssets()";
    string constant REBALANCE_01 = "REBALANCE_01: rebalance does not change balanceOf";
    string constant STRATEGY_01 = "STRATEGY_01: Removing a strategy does not change balanceOf";
    string constant STRATEGY_02 = "STRATEGY_02: The SizeMetaVault always has at least 1 strategy";
    string constant TOTAL_ASSETS_CAP_01 =
        "TOTAL_ASSETS_CAP_01: Deposit reverts if amount + totalAssets() >= totalAssetsCap()";
}
