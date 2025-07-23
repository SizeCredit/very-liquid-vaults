// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Timelock
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Timelock contract for the Size Meta Vault system
/// @dev Provides common timelock functionality
abstract contract Timelock {
    uint256 public constant MINIMUM_TIMELOCK_DURATION = 15 minutes;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(bytes4 sig => uint256 duration) public timelockDurations;
    mapping(bytes4 sig => uint256 timestamp) public proposedTimestamps;
    mapping(bytes4 sig => bytes32 calldataHash) public proposedCalldataHashes;
    uint256[47] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error TimelockDurationTooShort(bytes4 sig, uint256 duration, uint256 minimumDuration);

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event TimelockDurationSet(bytes4 indexed sig, uint256 indexed durationBefore, uint256 indexed durationAfter);
    event ActionTimelocked(bytes4 indexed sig, bytes indexed data, uint256 indexed unlockTimestamp);
    event TimelockExpired(bytes4 indexed sig);

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier to update the timelocked state of a function
    /// @dev The user must call the function again with the same calldata to execute the function, otherwise it resets the timelock
    /// @param bypassTimelock If true, the timelock update is not performed
    modifier timelocked(bool bypassTimelock) {
        if (bypassTimelock) {
            _;
        } else {
            bytes4 sig = msg.sig;
            bytes memory data = msg.data;

            if (proposedCalldataHashes[sig] != keccak256(data)) {
                proposedTimestamps[sig] = block.timestamp;
                proposedCalldataHashes[sig] = keccak256(data);
                emit ActionTimelocked(sig, data, _getTimelockDuration(sig) + proposedTimestamps[sig]);
            } else if (block.timestamp >= _getTimelockDuration(sig) + proposedTimestamps[sig]) {
                delete proposedTimestamps[sig];
                delete proposedCalldataHashes[sig];
                emit TimelockExpired(sig);
            }

            _;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the function is timelocked
    /// @dev Returns true if the function is timelocked, false otherwise
    function isTimelocked(bytes4 sig) public view returns (bool) {
        return block.timestamp < _getTimelockDuration(sig) + proposedTimestamps[sig];
    }

    /// @notice Checks if the current function is timelocked
    /// @dev Returns true if the current function is timelocked, false otherwise
    function _isTimelocked() internal view returns (bool) {
        return isTimelocked(msg.sig);
    }

    /// @notice Sets the timelock duration for a specific function
    /// @dev Updating the timelock duration has immediate effect on the timelocked functions
    function _setTimelockDuration(bytes4 sig, uint256 duration) internal {
        if (duration < MINIMUM_TIMELOCK_DURATION) {
            revert TimelockDurationTooShort(sig, duration, MINIMUM_TIMELOCK_DURATION);
        }

        uint256 durationBefore = timelockDurations[sig];
        timelockDurations[sig] = duration;
        emit TimelockDurationSet(sig, durationBefore, duration);
    }

    /// @notice Gets the timelock duration for a specific function
    function _getTimelockDuration(bytes4 sig) internal view returns (uint256) {
        return Math.max(MINIMUM_TIMELOCK_DURATION, timelockDurations[sig]);
    }
}
