// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SizeVaultStrategistActions} from "@src/SizeVaultStrategistActions.sol";

abstract contract SizeVaultView is SizeVaultStrategistActions {
    using EnumerableSet for EnumerableSet.AddressSet;

    function getStrategies() external view returns (address[] memory) {
        return strategies.values();
    }

    function getStrategy(uint256 index) external view returns (address) {
        return strategies.at(index);
    }
}
