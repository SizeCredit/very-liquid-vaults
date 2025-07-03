// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SIZE_VAULT_ROLE} from "@src/Auth.sol";

/// @title CashStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that only holds cash assets without investing in external protocols
/// @dev Implements IStrategy interface for cash management within the Size Meta Vault system
contract CashStrategyVault is BaseVault, IStrategy {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              SIZE VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfers assets from this strategy to another address
    /// @dev Only callable by addresses with SIZE_VAULT_ROLE (typically the meta vault)
    function transferAssets(address to, uint256 assets)
        external
        override
        notPaused
        onlyAuth(SIZE_VAULT_ROLE)
        nonReentrant
    {
        IERC20(asset()).safeTransfer(to, assets);
        emit TransferAssets(to, assets);
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Skims idle assets (no-op for cash strategy)
    /// @dev Since this is a cash strategy, there are no assets to invest, so this just emits an event
    function skim() external override notPaused nonReentrant {
        emit Skim();
    }
}
