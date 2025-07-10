// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ForkTest} from "@test/fork/ForkTest.t.sol";
import {IPoolConfigurator} from "@aave/contracts/interfaces/IPoolConfigurator.sol";
import {ReserveConfiguration} from "@aave/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "@aave/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseVault} from "@src/BaseVault.sol";

contract AaveStrategyVaultForkTest is ForkTest {
    using SafeERC20 for IERC20Metadata;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IPool public aavePool;
    IPoolConfigurator public aavePoolConfigurator =
        IPoolConfigurator(address(0x5731a04B1E775f0fdd454Bf70f3335886e9A96be));
    address public aavePoolAdmin = 0x9390B1735def18560c509E2d0bc090E9d6BA257a;

    function setUp() public override {
        super.setUp();

        // can choose a better value
        FIRST_DEPOSIT_AMOUNT = 10e6;

        aavePool = IPool(address(0xA238Dd80C259a72e81d7e4664a9801593F98d1c5));
        _mint(asset, address(this), FIRST_DEPOSIT_AMOUNT);

        address implementation = address(new AaveStrategyVault());
        bytes memory initializationData = abi.encodeCall(
            AaveStrategyVault.initialize,
            (
                auth,
                IERC20(address(asset)),
                string.concat("Aave ", asset.name(), " Strategy"),
                string.concat("aave", asset.symbol()),
                FIRST_DEPOSIT_AMOUNT,
                aavePool
            )
        );
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        aaveStrategyVault = AaveStrategyVault(Create2.computeAddress(salt, keccak256(creationCode)));
        console.log("first deposit amount", FIRST_DEPOSIT_AMOUNT);
        asset.forceApprove(address(aaveStrategyVault), FIRST_DEPOSIT_AMOUNT);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }

    function test_fork() public {
        console.log(aavePool.getConfiguration(address(asset)).getFrozen());

        vm.prank(aavePoolAdmin);
        aavePoolConfigurator.setReserveFreeze(address(asset), true);

        console.log(aavePool.getConfiguration(address(asset)).getFrozen());
    }

    function test_AaveStrategyVault_initialize_with_zero_address_pool_must_revert() public {
        _mint(asset, address(this), FIRST_DEPOSIT_AMOUNT);

        address implementation = address(new AaveStrategyVault());
        bytes memory initializationData = abi.encodeCall(
            AaveStrategyVault.initialize,
            (
                auth,
                IERC20(address(asset)),
                string.concat("Aave ", asset.name(), " Strategy"),
                string.concat("aave", asset.symbol()),
                FIRST_DEPOSIT_AMOUNT,
                IPool(address(0))
            )
        );
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        aaveStrategyVault = AaveStrategyVault(Create2.computeAddress(salt, keccak256(creationCode)));
        asset.forceApprove(address(aaveStrategyVault), FIRST_DEPOSIT_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }

    // function test_AaveStrategyVault_maxDeposit_getActive_false_must_return_zero()
    //     public
    // {
    //     vm.prank(aavePoolAdmin);
    //     aavePoolConfigurator.setReserveActive(address(asset), false);

    //     uint256 returnValue = aaveStrategyVault.maxDeposit(address(this));
    //     console.log(returnValue);

    //     assertEq(returnValue, 0);
    // }

    function test_AaveStrategyVault_maxDeposit_if_frozen_must_return_zero() public {
        vm.prank(aavePoolAdmin);
        aavePoolConfigurator.setReserveFreeze(address(asset), true);

        uint256 returnValue = aaveStrategyVault.maxDeposit(address(this));

        assertEq(returnValue, 0);
        assertEq(aavePool.getConfiguration(address(asset)).getFrozen(), true);
    }

    function test_AaveStrategyVault_maxDeposit_maxWithdraw_maxRedeen_if_posed_must_return_zero() public {
        vm.prank(aavePoolAdmin);
        aavePoolConfigurator.setReservePause(address(asset), true);

        uint256 maxDepositReturnValue = aaveStrategyVault.maxDeposit(address(this));
        uint256 maxWithdrawReturnValue = aaveStrategyVault.maxWithdraw(address(this));
        uint256 maxRedeemReturnValue = aaveStrategyVault.maxRedeem(address(this));

        assertEq(maxDepositReturnValue, 0);
        assertEq(maxWithdrawReturnValue, 0);
        assertEq(maxRedeemReturnValue, 0);
    }

    function test_AaveStrategyVault_maxDeposit_if_no_supplyCap_returns_max_uint256() public {
        vm.prank(aavePoolAdmin);
        aavePoolConfigurator.setSupplyCap(address(asset), 0);

        uint256 maxDepositReturnValue = aaveStrategyVault.maxDeposit(address(this));

        assertEq(maxDepositReturnValue, type(uint256).max);
    }
}
