// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

abstract contract ReentrancyGuardUpgradeableWithViewModifier is ReentrancyGuardUpgradeable {
    /// @dev See https://github.com/OpenZeppelin/openzeppelin-contracts/pull/5800
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    /// @dev See https://github.com/OpenZeppelin/openzeppelin-contracts/pull/5800
    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) revert ReentrancyGuardReentrantCall();
    }
}
