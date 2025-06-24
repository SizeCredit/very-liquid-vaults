// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract SizeVaultStorage {
    EnumerableSet.AddressSet internal strategies;
    DoubleEndedQueue.Bytes32Deque internal withdrawStrategyOrder;
    DoubleEndedQueue.Bytes32Deque internal depositStrategyOrder;
}
