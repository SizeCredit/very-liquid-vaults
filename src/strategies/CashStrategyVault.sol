// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SIZE_VAULT_ROLE} from "@src/Auth.sol";

/// @title CashStrategyVault
/// @notice A strategy that only holds cash assets, and does not invest in any other vaults
contract CashStrategyVault is BaseStrategyVault {
    using SafeERC20 for IERC20;

    function pullAssets(address to, uint256 amount)
        external
        override
        notPaused
        onlyAuth(SIZE_VAULT_ROLE)
        nonReentrant
    {
        if (to == address(0)) {
            revert NullAddress();
        }

        IERC20(asset()).safeTransfer(to, amount);
        emit PullAssets(to, amount);
    }
}
