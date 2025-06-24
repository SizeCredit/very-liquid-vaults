// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";

abstract contract BaseStrategy is IStrategy, ERC4626Upgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    SizeVault public sizeVault;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

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
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(sizeVault_ != SizeVault(address(0)), NullAddress());

        sizeVault = sizeVault_;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        require(!sizeVault.paused(), PausableUpgradeable.EnforcedPause());
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override {}

    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }
}
