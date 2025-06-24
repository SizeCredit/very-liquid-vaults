// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

library AddressDequeLibrary {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    function pushBack(DoubleEndedQueue.Bytes32Deque storage deque, address value) internal {
        deque.pushBack(bytes32(uint256(uint160(value))));
    }
}
