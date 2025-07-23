// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {BaseStrategy} from "@src/strategies/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Auth, SIZE_VAULT_ROLE} from "@src/utils/Auth.sol";

/// @title ERC4626StrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that invests assets in an external ERC4626-compliant vault
/// @dev Wraps an external ERC4626 vault to provide strategy functionality for the Size Meta Vault
contract ERC4626StrategyVault is BaseStrategy {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC4626 public vault;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event VaultSet(address indexed vault);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the ERC4626StrategyVault with an external vault
    /// @dev Sets the external vault and calls parent initialization
    function initialize(
        Auth auth_,
        string memory name_,
        string memory symbol_,
        address fundingAccount,
        uint256 firstDepositAmount,
        IERC4626 vault_
    ) public virtual initializer {
        if (address(vault_) == address(0)) {
            revert NullAddress();
        }

        vault = vault_;
        emit VaultSet(address(vault_));

        super.initialize(auth_, IERC20(address(vault_.asset())), name_, symbol_, fundingAccount, firstDepositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Invests any idle assets sitting in this contract
    /// @dev Deposits any assets held by this contract into the external vault
    function skim() external override nonReentrant notPaused {
        uint256 assets = IERC20(asset()).balanceOf(address(this));
        IERC20(asset()).forceApprove(address(vault), assets);
        // slither-disable-next-line unused-return
        vault.deposit(assets, address(this));
        emit Skim();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum amount that can be deposited
    /// @dev Delegates to the external vault's maxDeposit function
    function maxDeposit(address receiver) public view override(BaseVault) returns (uint256) {
        return Math.min(vault.maxDeposit(address(this)), super.maxDeposit(receiver));
    }

    /// @notice Returns the maximum number of shares that can be minted
    /// @dev Delegates to the external vault's maxMint function
    function maxMint(address receiver) public view override(BaseVault) returns (uint256) {
        return Math.min(vault.maxMint(address(this)), super.maxMint(receiver));
    }

    /// @notice Returns the maximum amount that can be withdrawn by an owner
    /// @dev Limited by both owner's balance and external vault's withdrawal capacity
    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            return _sizeMetaVaultMaxWithdraw();
        } else {
            return Math.min(_convertToAssets(balanceOf(owner), Math.Rounding.Floor), vault.maxWithdraw(address(this)));
        }
    }

    /// @notice Returns the maximum number of shares that can be redeemed
    /// @dev Limited by both owner's balance and external vault's redemption capacity
    function maxRedeem(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            return _sizeMetaVaultMaxRedeem();
        } else {
            return Math.min(balanceOf(owner), _convertToShares(vault.maxWithdraw(address(this)), Math.Rounding.Floor));
        }
    }

    /// @notice Returns the total assets managed by this strategy
    /// @dev Converts the external vault shares held by this contract to asset value
    /// @return The total assets under management
    function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    /// @notice Internal deposit function that invests in the external vault
    /// @dev Calls parent deposit then invests the assets in the external vault
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(vault), assets);
        // slither-disable-next-line unused-return
        vault.deposit(assets, address(this));
    }

    /// @notice Internal withdraw function that redeems from the external vault
    /// @dev Withdraws from the external vault then calls parent withdraw
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
        // slither-disable-next-line unused-return
        vault.withdraw(assets, address(this), address(this));
        uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
        assets = balanceAfter - balanceBefore;

        if (auth.hasRole(SIZE_VAULT_ROLE, owner)) {
            // do not _burn shares
            SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
            emit Withdraw(caller, receiver, owner, assets, shares);
        } else {
            super._withdraw(caller, receiver, owner, assets, shares);
        }
    }
}
