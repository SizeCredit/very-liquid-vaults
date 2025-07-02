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

contract BaseVault is
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
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error NullAddress();
    error NullAmount();

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuthSet(address indexed authBefore, address indexed authAfter);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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

        deposit(firstDepositAmount_, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAuth(bytes32 role) {
        if (!auth.hasRole(role, msg.sender)) {
            revert IAccessControl.AccessControlUnauthorizedAccount(msg.sender, role);
        }
        _;
    }

    modifier notPaused() {
        if (paused() || auth.paused()) revert EnforcedPause();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyAuth(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyAuth(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyAuth(PAUSER_ROLE) {
        _unpause();
    }

    function decimals() public view virtual override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
        return super.decimals();
    }

    function _update(address from, address to, uint256 value) internal override notPaused {
        super._update(from, to, value);
    }
}
