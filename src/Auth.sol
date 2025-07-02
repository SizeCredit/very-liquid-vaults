// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/MulticallUpgradeable.sol";

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
bytes32 constant SIZE_VAULT_ROLE = keccak256("SIZE_VAULT_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

contract Auth is UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable, MulticallUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __Multicall_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(STRATEGIST_ROLE, admin_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
