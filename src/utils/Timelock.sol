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

    struct TimelockData {
        uint256 duration;
        uint256 proposedTimestamp;
        bytes32 proposedCalldataHash;
        bool isEditable;
    }

    mapping(bytes4 sig => TimelockData) public timelockData;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error TimelockDurationTooShort(bytes4 sig, uint256 duration, uint256 minimumDuration);
    error TimelockNotEditable(bytes4 sig);

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event TimelockDurationSet(
        bytes4 indexed sig, bool indexed isEditable, uint256 durationBefore, uint256 durationAfter
    );
    event ActionTimelocked(bytes4 indexed sig, bytes indexed data, uint256 indexed unlockTimestamp);
    event TimelockExpired(bytes4 indexed sig);

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the function is timelocked
    /// @return True if the function is timelocked, false otherwise
    function isTimelocked(bytes4 sig) public view returns (bool) {
        return block.timestamp < _getTimelockDuration(sig) + timelockData[sig].proposedTimestamp;
    }

    /// @notice Gets the timelock data for a specific function
    function getTimelockData(bytes4 sig) public view returns (TimelockData memory) {
        return timelockData[sig];
    }

    /// @notice Updates the timelock state and checks if the current function is timelocked
    /// @return True if the current function is timelocked, false otherwise
    function _updateTimelockStateAndCheckIfTimelocked() internal returns (bool) {
        bytes4 sig = msg.sig;
        bytes memory data = msg.data;

        if (timelockData[sig].proposedCalldataHash != keccak256(data)) {
            timelockData[sig].proposedTimestamp = block.timestamp;
            timelockData[sig].proposedCalldataHash = keccak256(data);
            emit ActionTimelocked(sig, data, _getTimelockDuration(sig) + timelockData[sig].proposedTimestamp);
        } else if (block.timestamp >= _getTimelockDuration(sig) + timelockData[sig].proposedTimestamp) {
            delete timelockData[sig].proposedTimestamp;
            delete timelockData[sig].proposedCalldataHash;
            emit TimelockExpired(sig);
        }

        return isTimelocked(msg.sig);
    }

    /// @notice Sets the timelock duration for a specific function
    /// @dev Updating the timelock duration has immediate effect on the timelocked functions
    function _setTimelockDuration(bytes4 sig, uint256 duration, bool isEditable) internal {
        if (duration < MINIMUM_TIMELOCK_DURATION) {
            revert TimelockDurationTooShort(sig, duration, MINIMUM_TIMELOCK_DURATION);
        }
        if (timelockData[sig].duration > 0 && !timelockData[sig].isEditable) {
            revert TimelockNotEditable(sig);
        }

        uint256 durationBefore = timelockData[sig].duration;
        timelockData[sig].duration = duration;
        timelockData[sig].isEditable = isEditable;
        emit TimelockDurationSet(sig, isEditable, durationBefore, duration);
    }

    /// @notice Sets the timelock duration for a specific function
    /// @dev Updating the timelock duration has immediate effect on the timelocked functions
    function _setTimelockDuration(bytes4 sig, uint256 duration) internal {
        _setTimelockDuration(sig, duration, timelockData[sig].isEditable);
    }

    /// @notice Gets the timelock duration for a specific function
    function _getTimelockDuration(bytes4 sig) internal view returns (uint256) {
        return Math.max(MINIMUM_TIMELOCK_DURATION, timelockData[sig].duration);
    }
}
