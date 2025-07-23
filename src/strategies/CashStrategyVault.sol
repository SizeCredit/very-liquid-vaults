// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";

/// @title CashStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that only holds cash assets without investing in external protocols
/// @dev Extends BaseStrategy for cash management within the Size Meta Vault system
contract CashStrategyVault is BaseVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Skims idle assets (no-op for cash strategy)
    function skim() external override nonReentrant notPaused {
        emit Skim();
    }
}
