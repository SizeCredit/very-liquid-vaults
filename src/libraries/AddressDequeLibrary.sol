// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

type AddressDeque is DoubleEndedQueue.Bytes32Deque;

library AddressDequeLibrary {
    using DoubleEndedQueue for AddressDeque;

    function pushBack(AddressDeque storage deque, address value) internal {
        deque.pushBack(bytes32(uint256(uint160(value))));
    }
}
