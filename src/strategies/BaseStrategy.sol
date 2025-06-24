    // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";

abstract contract BaseStrategy is
    IStrategy,
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    SizeVault public sizeVault;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlySizeVault();
    error NullAddress();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(SizeVault sizeVault_, IERC20 asset_, string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC4626_init(asset_);
        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(sizeVault_ != SizeVault(address(0)), NullAddress());

        sizeVault = sizeVault_;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenSizeVaultNotPaused() {
        require(!sizeVault.paused(), EnforcedPause());
        _;
    }

    modifier onlySizeVault() {
        require(msg.sender == address(sizeVault), OnlySizeVault());
        _;
    }

    modifier onlySizeVaultAdmin() {
        require(
            sizeVault.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            AccessControlUnauthorizedAccount(msg.sender, DEFAULT_ADMIN_ROLE)
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlySizeVaultAdmin {}

    function _update(address from, address to, uint256 value) internal override whenNotPaused whenSizeVaultNotPaused {
        super._update(from, to, value);
    }
}
