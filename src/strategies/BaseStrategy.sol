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
import {STRATEGIST_ROLE, PAUSER_ROLE} from "@src/SizeVault.sol";
import {MulticallUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/MulticallUpgradeable.sol";

abstract contract BaseStrategy is
    IStrategy,
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
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
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event SizeVaultSet(address indexed sizeVaultBefore, address indexed sizeVaultAfter);
    event PullAssets(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(SizeVault sizeVault_, string memory name_, string memory symbol_) public initializer {
        __ERC4626_init(IERC20(address(sizeVault_.asset())));
        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __Multicall_init();
        __UUPSUpgradeable_init();

        require(sizeVault_ != SizeVault(address(0)), NullAddress());

        emit SizeVaultSet(address(0), address(sizeVault_));
        sizeVault = sizeVault_;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlySizeVault() {
        require(msg.sender == address(sizeVault), OnlySizeVault());
        _;
    }

    modifier onlySizeVaultHasRole(bytes32 role) {
        require(sizeVault.hasRole(role, msg.sender), AccessControlUnauthorizedAccount(msg.sender, role));
        _;
    }

    modifier whenNotPausedAndSizeVaultNotPaused() {
        require(!paused() && !sizeVault.paused(), EnforcedPause());
        _;
    }

    modifier notNullAddress(address address_) {
        require(address_ != address(0), NullAddress());
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function pause() external onlySizeVaultHasRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlySizeVaultHasRole(PAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlySizeVaultHasRole(DEFAULT_ADMIN_ROLE) {}

    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPausedAndSizeVaultNotPaused
        nonReentrant
    {
        super._update(from, to, value);
    }
}
