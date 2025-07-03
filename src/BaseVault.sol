// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from
    "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MulticallUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/MulticallUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Auth} from "@src/Auth.sol";
import {DEFAULT_ADMIN_ROLE, PAUSER_ROLE} from "@src/Auth.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

/// @title BaseVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Abstract base contract for all vaults in the Size Meta Vault system
/// @dev Provides common functionality including ERC4626 compliance, access control, and upgradeability
abstract contract BaseVault is
    ERC4626Upgradeable,
    ERC20PermitUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    MulticallUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    Auth public auth;
    uint256 public deadAssets;
    uint256[48] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error NullAddress();
    error NullAmount();

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuthSet(address indexed authBefore, address indexed authAfter);
    event DeadAssetsSet(uint256 deadAssets);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the BaseVault with necessary parameters
    /// @dev Sets up all inherited contracts and makes the first deposit to prevent inflation attacks
    function initialize(
        Auth auth_,
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 firstDepositAmount_
    ) public virtual initializer {
        __ERC4626_init(asset_);
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __ReentrancyGuard_init();
        __Pausable_init();
        __Multicall_init();
        __UUPSUpgradeable_init();

        if (address(auth_) == address(0)) {
            revert NullAddress();
        }
        if (firstDepositAmount_ == 0) {
            revert NullAmount();
        }

        auth = auth_;
        emit AuthSet(address(0), address(auth_));

        deadAssets = firstDepositAmount_;
        emit DeadAssetsSet(firstDepositAmount_);

        deposit(firstDepositAmount_, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier to restrict function access to addresses with specific roles
    /// @dev Reverts if the caller doesn't have the required role
    modifier onlyAuth(bytes32 role) {
        if (!auth.hasRole(role, msg.sender)) {
            revert IAccessControl.AccessControlUnauthorizedAccount(msg.sender, role);
        }
        _;
    }

    /// @notice Modifier to ensure the contract is not paused
    /// @dev Checks both local pause state and global pause state from Auth
    modifier notPaused() {
        if (paused() || auth.paused()) revert EnforcedPause();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Authorizes contract upgrades
    /// @dev Only addresses with DEFAULT_ADMIN_ROLE can authorize upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyAuth(DEFAULT_ADMIN_ROLE) {}

    /// @notice Pauses the vault
    /// @dev Only addresses with PAUSER_ROLE can pause the vault
    function pause() external onlyAuth(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the vault
    /// @dev Only addresses with PAUSER_ROLE can unpause the vault
    function unpause() external onlyAuth(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Returns the number of decimals for the vault token
    /// @dev Overrides both ERC20 and ERC4626 decimals functions
    /// @return The number of decimals (matches the underlying asset)
    function decimals() public view virtual override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
        return super.decimals();
    }

    /// @notice Internal function called during token transfers
    /// @dev Ensures transfers only happen when the contract is not paused and that no reentrancy is possible
    function _update(address from, address to, uint256 value) internal override notPaused nonReentrant {
        super._update(from, to, value);
    }
}
