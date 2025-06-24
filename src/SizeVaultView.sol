// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SizeVaultStorage} from "@src/SizeVaultStorage.sol";

contract SizeVaultView is SizeVaultStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    function getStrategies() external view returns (address[] memory) {
        return strategies.values();
    }

    function getStrategy(uint256 index) external view returns (address) {
        return strategies.at(index);
    }
}
