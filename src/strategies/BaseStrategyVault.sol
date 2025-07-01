// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeVault} from "@src/SizeVault.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {Auth} from "@src/Auth.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseStrategyVault is IStrategy, BaseVault {
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    SizeVault public sizeVault;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlySizeVault();
    error NullAmount();
    error InvalidAsset();

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

    function initialize(
        Auth auth_,
        SizeVault sizeVault_,
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 firstDepositAmount_
    ) public virtual initializer {
        super.initialize(auth_, asset_, name_, symbol_, firstDepositAmount_);

        if (sizeVault_ == SizeVault(address(0))) {
            revert NullAddress();
        }
        if (sizeVault_.asset() != address(asset_)) {
            revert InvalidAsset();
        }
        if (firstDepositAmount_ == 0) {
            revert NullAmount();
        }

        sizeVault = sizeVault_;
        emit SizeVaultSet(address(0), address(sizeVault_));
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlySizeVault() {
        if (msg.sender != address(sizeVault)) {
            revert OnlySizeVault();
        }
        _;
    }
}
