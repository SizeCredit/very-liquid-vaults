// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DEFAULT_ADMIN_ROLE} from "@src/SizeVault.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/contracts/interfaces/IAToken.sol";

/// @title AaveStrategyVault
/// @notice A strategy that invests assets in Aave
/// @dev Reference https://github.com/superform-xyz/super-vaults/blob/8bc1d1bd1579f6fb9a047802256ed3a2bf15f602/src/aave-v3/AaveV3ERC4626Reinvest.sol
contract AaveStrategyVault is BaseStrategyVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IPool public pool;
    IAToken public aToken;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF;
    uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
    uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;
    uint256 internal constant PAUSED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF;
    uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event PoolSet(address indexed poolBefore, address indexed poolAfter);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(SizeVault sizeVault_, string memory name_, string memory symbol_, IPool pool_)
        public
        virtual
        initializer
    {
        super.initialize(sizeVault_, name_, symbol_);

        require(address(pool_) != address(0), NullAddress());

        pool = pool_;
        aToken = IAToken(pool.getReserveData(address(asset())).aTokenAddress);
        emit PoolSet(address(0), address(pool_));
    }

    function pullAssets(address to, uint256 amount)
        external
        override
        whenNotPausedAndSizeVaultNotPaused
        onlySizeVault
        nonReentrant
        notNullAddress(to)
    {
        pool.withdraw(asset(), amount, to);

        emit PullAssets(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        // check if asset is paused
        uint256 configData = pool.getReserveData(asset()).configuration.data;
        if (!(_getActive(configData) && !_getFrozen(configData) && !_getPaused(configData))) {
            return 0;
        }

        // handle supply cap
        uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
        if (supplyCapInWholeTokens == 0) {
            return type(uint256).max;
        }

        uint8 tokenDecimals = _getDecimals(configData);
        uint256 supplyCap = supplyCapInWholeTokens * 10 ** tokenDecimals;
        if (aToken.totalSupply() >= supplyCap) return 0;
        return supplyCap - aToken.totalSupply();
    }

    function maxMint(address receiver) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return convertToShares(maxDeposit(receiver));
    }

    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        // check if asset is paused
        uint256 configData = pool.getReserveData(asset()).configuration.data;
        if (!(_getActive(configData) && !_getPaused(configData))) {
            return 0;
        }

        uint256 cash = IERC20(asset()).balanceOf(address(aToken));
        uint256 assetsBalance = convertToAssets(balanceOf(owner));
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        // check if asset is paused
        uint256 configData = pool.getReserveData(asset()).configuration.data;
        if (!(_getActive(configData) && !_getPaused(configData))) {
            return 0;
        }

        uint256 cash = IERC20(asset()).balanceOf(address(aToken));
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf(owner);
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    function totalAssets() public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        /// @notice aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
        return aToken.balanceOf(address(this));
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).forceApprove(address(pool), assets);
        pool.supply(asset(), assets, address(this), 0);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        pool.withdraw(asset(), assets, address(this));
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _getDecimals(uint256 configData) internal pure returns (uint8) {
        return uint8((configData & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION);
    }

    function _getActive(uint256 configData) internal pure returns (bool) {
        return configData & ~ACTIVE_MASK != 0;
    }

    function _getFrozen(uint256 configData) internal pure returns (bool) {
        return configData & ~FROZEN_MASK != 0;
    }

    function _getPaused(uint256 configData) internal pure returns (bool) {
        return configData & ~PAUSED_MASK != 0;
    }

    function _getSupplyCap(uint256 configData) internal pure returns (uint256) {
        return (configData & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }
}
