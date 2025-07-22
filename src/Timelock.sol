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
    mapping(bytes4 sig => bytes data) public proposedCalldatas;
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
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the function is timelocked and returns true if it is
    /// @dev The user must call the function again with the same calldata to execute the function, otherwise it resets the timelock
    /// @dev Updates the timelocked state of the function
    function _timelocked(bytes4 sig) internal returns (bool timelocked) {
        bytes memory data = msg.data;

        uint256 timelockDuration = Math.max(MINIMUM_TIMELOCK_DURATION, timelockDurations[sig]);

        if (keccak256(proposedCalldatas[sig]) != keccak256(data)) {
            proposedTimestamps[sig] = block.timestamp;
            proposedCalldatas[sig] = data;
            emit ActionTimelocked(sig, data, timelockDuration + proposedTimestamps[sig]);
            return true;
        } else if (block.timestamp >= timelockDuration + proposedTimestamps[sig]) {
            delete proposedTimestamps[sig];
            delete proposedCalldatas[sig];
            emit TimelockExpired(sig);
            return false;
        } else {
            return true;
        }
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
}
