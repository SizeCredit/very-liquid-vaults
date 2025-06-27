// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/SizeVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title ERC4626StrategyVault
/// @notice A strategy that invests assets in an ERC4626 vault
contract ERC4626StrategyVault is BaseStrategyVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC4626 public vault;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event VaultSet(address indexed vaultBefore, address indexed vaultAfter);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(SizeVault sizeVault_, string memory name_, string memory symbol_, IERC4626 vault_)
        public
        virtual
        initializer
    {
        super.initialize(sizeVault_, name_, symbol_);

        require(address(vault_) != address(0), NullAddress());

        vault = vault_;
        emit VaultSet(address(0), address(vault_));
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function pullAssets(address to, uint256 amount)
        external
        override
        whenNotPausedAndSizeVaultNotPaused
        onlySizeVault
        nonReentrant
        notNullAddress(to)
    {
        vault.withdraw(amount, to, address(this));
        emit PullAssets(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxDeposit(address(this));
    }

    function maxMint(address) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.maxMint(address(this));
    }

    function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(vault), assets);
        vault.deposit(assets, address(this));
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        vault.withdraw(assets, address(this), address(this));
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
