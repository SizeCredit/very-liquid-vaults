// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {BaseStrategy} from "@src/strategies/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SIZE_VAULT_ROLE} from "@src/utils/Auth.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title CashStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that only holds cash assets without investing in external protocols
/// @dev Extends BaseVault for cash management within the Size Meta Vault system
contract CashStrategyVault is BaseStrategy {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Skims idle assets (no-op for cash strategy)
    /// @dev Since this is a cash strategy, there are no assets to invest, so this just emits an event
    function skim() external override nonReentrant notPaused {
        emit Skim();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum amount that can be withdrawn by an owner
    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            return _sizeMetaVaultMaxWithdraw();
        } else {
            return super.maxWithdraw(owner);
        }
    }

    /// @notice Returns the maximum number of shares that can be redeemed
    function maxRedeem(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            return _sizeMetaVaultMaxRedeem();
        } else {
            return super.maxRedeem(owner);
        }
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            // do not _burn shares
            SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
            emit Withdraw(caller, receiver, owner, assets, shares);
        } else {
            super._withdraw(caller, receiver, owner, assets, shares);
        }
    }
}
