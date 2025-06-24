// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {AddressDeque} from "@src/libraries/AddressDequeLibrary.sol";

abstract contract SizeVaultStorage {
    AddressDeque internal withdrawStrategyOrder;
    AddressDeque internal depositStrategyOrder;
}
