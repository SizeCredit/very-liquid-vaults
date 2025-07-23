// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {SIZE_VAULT_ROLE} from "@src/utils/Auth.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title BaseStrategy
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Abstract base contract for all strategies in the Size Meta Vault system
abstract contract BaseStrategy is BaseVault {
    /*//////////////////////////////////////////////////////////////
                              ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the allowance of the spender for the owner
    /// @dev Returns type(uint256).max if the spender has SIZE_VAULT_ROLE, since `rebalance` can be called to freely transfer assets between strategies
    function allowance(address owner, address spender)
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20)
        returns (uint256)
    {
        return auth.hasRole(SIZE_VAULT_ROLE, spender) ? type(uint256).max : super.allowance(owner, spender);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw function that skips _burn shares if called by the SizeMetaVault
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
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

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum amount that can be withdrawn by the SizeMetaVault
    function _sizeMetaVaultMaxWithdraw() internal view returns (uint256) {
        return Math.saturatingSub(_convertToAssets(totalSupply(), Math.Rounding.Floor), deadAssets);
    }

    /// @notice Returns the maximum number of shares that can be redeemed by the SizeMetaVault
    function _sizeMetaVaultMaxRedeem() internal view returns (uint256) {
        return Math.saturatingSub(totalSupply(), _convertToShares(deadAssets, Math.Rounding.Ceil));
    }
}
