// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/utils/BaseVault.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title NonReentrantVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A vault that is non-reentrant
/// @dev Extends BaseVault to make it non-reentrant
abstract contract NonReentrantVault is BaseVault {
    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        shares = super.deposit(assets, receiver);
        emit VaultStatus(totalSupply(), totalAssets());
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        nonReentrant
        returns (uint256 assets)
    {
        assets = super.mint(shares, receiver);
        emit VaultStatus(totalSupply(), totalAssets());
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, owner);
        emit VaultStatus(totalSupply(), totalAssets());
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        nonReentrant
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, owner);
        emit VaultStatus(totalSupply(), totalAssets());
    }
}
