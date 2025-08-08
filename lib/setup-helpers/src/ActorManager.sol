// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {EnumerableSet} from "./EnumerableSet.sol";

/// @dev This is the source of truth for the actors being used in the test
/// @notice No actors should be used in the suite without being added here first
abstract contract ActorManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    ///@notice The current actor being used
    address private _actor;

    ///@notice The list of all actors being used
    EnumerableSet.AddressSet private _actors;

    // If the current target is address(0) then it has not been setup yet and should revert
    error ActorNotSetup();
    // Do not allow duplicates
    error ActorExists();
    // If the actor does not exist
    error ActorNotAdded();
    // Do not allow the default actor
    error DefaultActor();

    /// @notice address(this) is the default actor
    constructor() {
        _actors.add(address(this));
        _actor = address(this);
    }

    /// @notice Returns the current active actor
    function _getActor() internal view returns (address) {
        return _actor;
    }

    /// @notice Returns all actors being used
    function _getActors() internal view returns (address[] memory) {
        return _actors.values();
    }

    /// @notice Adds an actor to the list of actors
    function _addActor(address target) internal {
        if (_actors.contains(target)) {
            revert ActorExists();
        }

        if (target == address(this)) {
            revert DefaultActor();
        }

        _actors.add(target);
    }

    /// @notice Removes an actor from the list of actors
    function _removeActor(address target) internal {
        if (!_actors.contains(target)) {
            revert ActorNotAdded();
        }

        if (target == address(this)) {
            revert DefaultActor();
        }

        _actors.remove(target);
    }

    /// @dev Expose this in the `TargetFunctions` contract to let the fuzzer switch actors
    ///   NOTE: We revert if the entropy is greater than the number of actors, for Halmos compatibility
    /// @dev This may reduce fuzzing performance if using multiple actors, if so add explicitly clamped handlers to ManagersTargets using the index of all added actors
    /// @notice Switches the current actor based on the entropy
    /// @param entropy The entropy to choose a random actor in the array for switching
    /// @return target The new active actor
    function _switchActor(uint256 entropy) internal returns (address target) {
        target = _actors.at(entropy);
        _actor = target;
    }
}
