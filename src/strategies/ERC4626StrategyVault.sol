// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Auth, SIZE_VAULT_ROLE} from "@src/Auth.sol";

/// @title ERC4626StrategyVault
/// @notice A strategy that invests assets in an ERC4626 vault
contract ERC4626StrategyVault is BaseVault, IStrategy {
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
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        Auth auth_,
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 firstDepositAmount,
        IERC4626 vault_
    ) public virtual initializer {
        if (address(vault_) == address(0)) {
            revert NullAddress();
        }

        vault = vault_;
        emit VaultSet(address(0), address(vault_));

        super.initialize(auth_, asset_, name_, symbol_, firstDepositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              SIZE VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function transferAssets(address to, uint256 assets)
        external
        override
        notPaused
        onlyAuth(SIZE_VAULT_ROLE)
        nonReentrant
    {
        vault.withdraw(assets, to, address(this));
        emit TransferAssets(to, assets);
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function skim() external override notPaused onlyAuth(SIZE_VAULT_ROLE) nonReentrant {
        uint256 assets = IERC20(asset()).balanceOf(address(this));
        IERC20(asset()).forceApprove(address(vault), assets);
        vault.deposit(assets, address(this));
        emit Skim();
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

    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return Math.min(_convertToAssets(balanceOf(owner), Math.Rounding.Floor), vault.maxWithdraw(address(this)));
    }

    function maxRedeem(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return Math.min(balanceOf(owner), _convertToShares(vault.maxWithdraw(address(this)), Math.Rounding.Floor));
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
