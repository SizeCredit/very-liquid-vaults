// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract SizeVaultStorage {
    EnumerableSet.AddressSet internal strategies;
}
