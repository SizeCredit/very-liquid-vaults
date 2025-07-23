// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {Auth, SIZE_VAULT_ROLE} from "@src/utils/Auth.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626StrategyVaultScript} from "@script/ERC4626StrategyVault.s.sol";
import {VaultMockRevertOnDeposit} from "@test/mocks/VaultMockRevertOnDeposit.t.sol";
import {VaultMockRevertOnWithdraw} from "@test/mocks/VaultMockRevertOnWithdraw.t.sol";
import {VaultMockAssetFeeOnWithdraw} from "@test/mocks/VaultMockAssetFeeOnWithdraw.t.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {console} from "forge-std/console.sol";
import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC4626Mock} from "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";

contract SizeMetaVaultTest is BaseTest {
    bool public expectRevert = false;

    enum VaultType {
        REVERT_ON_DEPOSIT,
        REVERT_ON_WITHDRAW,
        ASSET_FEE_ON_WITHDRAW
    }

    VaultMockRevertOnDeposit vault_revertDeposit;
    VaultMockRevertOnWithdraw vault_revertWithdraw;
    VaultMockAssetFeeOnWithdraw vault_assetFeeOnWithdraw;

    function test_SizeMetaVault_initialize() public view {
        assertEq(address(sizeMetaVault.asset()), address(erc20Asset));
        assertEq(sizeMetaVault.name(), string.concat("Size Meta ", erc20Asset.name(), " Vault"));
        assertEq(sizeMetaVault.symbol(), string.concat("szMeta", erc20Asset.symbol()));
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
        assertEq(sizeMetaVault.totalSupply(), sizeMetaVault.strategiesCount() * FIRST_DEPOSIT_AMOUNT + 1);
        assertEq(sizeMetaVault.balanceOf(address(this)), 0);
        assertEq(sizeMetaVault.allowance(address(this), address(this)), 0);
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
    }

    function test_SizeMetaVault_rebalance_cashStrategy_to_erc4626() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 cashStrategyDeadAssetsBefore = cashStrategyVault.deadAssets();

        uint256 amount = cashAssetsBefore - cashStrategyDeadAssetsBefore;

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, 0);

        uint256 cashAssetsAfter = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsAfter = erc4626StrategyVault.totalAssets();
        uint256 cashStrategyDeadAssetsAfter = cashStrategyVault.deadAssets();

        assertEq(cashAssetsAfter, cashStrategyDeadAssetsAfter);
        assertEq(cashStrategyDeadAssetsBefore, cashStrategyDeadAssetsAfter);
        assertEq(erc4626AssetsAfter, erc4626AssetsBefore + amount);
    }

    function test_SizeMetaVault_rebalance_erc4626_to_cashStrategy() public {
        IBaseVault[] memory strategies = new IBaseVault[](3);
        strategies[0] = erc4626StrategyVault;
        strategies[1] = cashStrategyVault;
        strategies[2] = aaveStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.reorderStrategies(strategies);

        _deposit(alice, sizeMetaVault, 100e6);

        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626StrategyDeadAssetsBefore = cashStrategyVault.deadAssets();

        uint256 amount = erc4626AssetsBefore - erc4626StrategyDeadAssetsBefore;

        vm.prank(strategist);
        sizeMetaVault.rebalance(erc4626StrategyVault, cashStrategyVault, amount, 0);

        uint256 erc4626AssetsAfter = erc4626StrategyVault.totalAssets();
        uint256 cashAssetsAfter = cashStrategyVault.totalAssets();
        uint256 erc4626StrategyDeadAssetsAfter = cashStrategyVault.deadAssets();

        assertEq(erc4626AssetsAfter, erc4626StrategyDeadAssetsAfter);
        assertEq(erc4626StrategyDeadAssetsBefore, erc4626StrategyDeadAssetsAfter);
        assertEq(cashAssetsAfter, cashAssetsBefore + amount);
    }

    function testFuzz_SizeMetaVault_rebalance_slippage_validation(uint256 amount, uint256 index) public {
        IBaseVault strategyFrom = cashStrategyVault;
        IBaseVault strategyTo = aaveStrategyVault;

        amount = bound(amount, strategyFrom.deadAssets(), 100e6);
        index = bound(index, 1e27, 1.3e27);

        _mint(erc20Asset, address(strategyFrom), amount * 2);
        _setLiquidityIndex(erc20Asset, index);

        vm.prank(strategist);
        try sizeMetaVault.rebalance(strategyFrom, strategyTo, amount, amount) {
            assertEq(expectRevert, false);
        } catch (bytes memory err) {
            assertEq(
                err, abi.encodeWithSelector(SizeMetaVault.TransferredAmountLessThanMin.selector, amount - 1, amount)
            );
        }
    }

    function test_SizeMetaVault_rebalance_slippage_validation_concrete() public {
        expectRevert = true;
        testFuzz_SizeMetaVault_rebalance_slippage_validation(90014716, 1200000000000000000000018340);
    }

    function test_SizeMetaVault_rebalance_with_slippage() public {
        uint256 amount = 30e6;

        _mint(erc20Asset, address(cashStrategyVault), amount * 2);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, amount);
    }

    function test_SizeMetaVault_addStrategies_validation() public {
        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = IBaseVault(address(0));

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        sizeMetaVault.addStrategies(strategies);
    }

    function test_SizeMetaVault_removeStrategies_validation() public {
        uint256 removeStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.removeStrategies.selector).duration;

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = IBaseVault(address(0));

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategies, IBaseVault(address(0)));

        vm.warp(block.timestamp + removeStrategiesTimelockDuration);
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(0)));
        sizeMetaVault.removeStrategies(strategies, IBaseVault(address(0)));
    }

    function test_SizeMetaVault_reorderStrategies_validation() public {
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.ArrayLengthMismatch.selector, 3, 0));
        sizeMetaVault.reorderStrategies(new IBaseVault[](0));

        IBaseVault[] memory strategiesWithZero = new IBaseVault[](3);
        strategiesWithZero[0] = cryticCashStrategyVault;
        strategiesWithZero[1] = cryticAaveStrategyVault;
        strategiesWithZero[2] = cryticERC4626StrategyVault;

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.reorderStrategies(strategiesWithZero);

        IBaseVault[] memory duplicates = new IBaseVault[](3);
        duplicates[0] = cashStrategyVault;
        duplicates[1] = erc4626StrategyVault;
        duplicates[2] = cashStrategyVault;

        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cashStrategyVault)));
        sizeMetaVault.reorderStrategies(duplicates);
    }

    function test_SizeMetaVault_rebalance_validation() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();

        uint256 amount = 5e6;

        // invalid strategyFrom reverts
        vm.prank(strategist);
        vm.expectRevert();
        sizeMetaVault.rebalance(IBaseVault(address(1)), erc4626StrategyVault, amount, 0);

        // validate strategyTo
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(1)));
        sizeMetaVault.rebalance(cashStrategyVault, IBaseVault(address(1)), amount, 0);

        // validate amount 0
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAmount.selector));
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, 0, 0);

        // validate amount > balance
        amount = 50e6;
        assertLt(cashAssetsBefore, amount);

        vm.prank(strategist);
        vm.expectRevert();
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, 0);
    }

    function test_SizeMetaVault_rebalance() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();

        uint256 amount = 50e6;
        assertLt(cashAssetsBefore, amount);

        vm.expectRevert();
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, 0);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, 5e6, 0);
        assertEq(cashStrategyVault.totalAssets(), cashAssetsBefore - 5e6);
        assertEq(erc4626StrategyVault.totalAssets(), erc4626AssetsBefore + 5e6);
    }

    function test_sizeMetaVault_rebalance_strategyFrom_not_added_must_not_revert() public {
        _deposit(alice, sizeMetaVault, 100e6);
        // remove cashStrategyVault; check removal; try to transfer from it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        IBaseVault[] memory strategiesToRemove = new IBaseVault[](1);
        strategiesToRemove[0] = cashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategiesToRemove, erc4626StrategyVault);

        uint256 removeStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.removeStrategies.selector).duration;
        vm.warp(block.timestamp + removeStrategiesTimelockDuration);

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategiesToRemove, erc4626StrategyVault);

        _mint(erc20Asset, address(cashStrategyVault), 2 * cashAssets);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        _deposit(bob, cashStrategyVault, 40e6);
        uint256 bobBalanceBefore = cashStrategyVault.balanceOf(bob);
        vm.prank(bob);
        cashStrategyVault.transfer(address(sizeMetaVault), bobBalanceBefore);

        uint256 assetsToTransfer = cashStrategyVault.balanceOf(address(sizeMetaVault));

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, assetsToTransfer, 0);
    }

    function test_sizeMetaVault_rebalance_strategyTo_not_added_must_revert() public {
        // remove erc4626StrategyVault; check removal; try to transfer to it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        IBaseVault[] memory strategiesToRemove = new IBaseVault[](1);
        strategiesToRemove[0] = erc4626StrategyVault;

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategiesToRemove, aaveStrategyVault);

        uint256 removeStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.removeStrategies.selector).duration;
        vm.warp(block.timestamp + removeStrategiesTimelockDuration);

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategiesToRemove, aaveStrategyVault);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(erc4626StrategyVault)));
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, cashAssets, 0);
    }

    function test_SizeMetaVault_skim() public {
        _deposit(alice, erc4626StrategyVault, 100e6);

        uint256 assetsBefore = sizeMetaVault.totalAssets();

        _mint(erc20Asset, address(sizeMetaVault), 300e6);

        vm.prank(strategist);
        sizeMetaVault.skim();

        uint256 assetsAfter = sizeMetaVault.totalAssets();
        assertEq(assetsAfter, assetsBefore + 300e6);
    }

    function test_SizeMetaVault_reorderStrategies() public {
        IBaseVault[] memory strategies = new IBaseVault[](3);
        strategies[0] = aaveStrategyVault;
        strategies[1] = erc4626StrategyVault;
        strategies[2] = cashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.reorderStrategies(strategies);

        assertEq(address(sizeMetaVault.strategies(0)), address(strategies[0]));
        assertEq(address(sizeMetaVault.strategies(1)), address(strategies[1]));
        assertEq(address(sizeMetaVault.strategies(2)), address(strategies[2]));

        assertTrue(sizeMetaVault.isStrategy(strategies[0]));
        assertTrue(sizeMetaVault.isStrategy(strategies[1]));
        assertTrue(sizeMetaVault.isStrategy(strategies[2]));
    }

    function test_SizeMetaVault_addStrategies() public {
        address oneStrategy = address(cryticCashStrategyVault);

        uint256 lengthBefore = sizeMetaVault.strategiesCount();

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = IBaseVault(oneStrategy);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);
        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        uint256 indexLastStrategy = lengthAfter - 1;

        address lastStrategyAdded = address(sizeMetaVault.strategies(indexLastStrategy));

        vm.assertEq(lengthAfter, lengthBefore + 1);
        vm.assertEq(oneStrategy, lastStrategyAdded);
    }

    function test_SizeMetaVault_addStrategies_duplicates_must_revert() public {
        IBaseVault[] memory strategies = new IBaseVault[](2);
        strategies[0] = cryticCashStrategyVault;
        strategies[1] = cryticCashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);
        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.addStrategies(strategies);
    }

    function test_SizeMetaVault_addStrategies_invalid_asset_must_revert() public {
        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = cashStrategyVaultWETH;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cashStrategyVaultWETH)));
        sizeMetaVault.addStrategies(strategies);
    }

    function test_SizeMetaVault_addStrategies_invalid_auth_must_revert() public {
        address invalidAuth = address(0xDEAD);

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = cryticCashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        vm.mockCall(
            address(cryticCashStrategyVault), abi.encodeWithSelector(IBaseVault.auth.selector), abi.encode(invalidAuth)
        );

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.addStrategies(strategies);
    }

    function test_SizeMetaVault_addStrategies_address_zero_must_revert() public {
        address addressZero = address(0);

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = IBaseVault(addressZero);

        uint256 lengthBefore = sizeMetaVault.strategiesCount();

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();

        assertEq(lengthBefore, lengthAfter);
    }

    function test_SizeMetaVault_addStrategies_removeStrategies_admin_is_not_timelocked() public {
        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = cryticCashStrategyVault;

        vm.prank(admin);
        sizeMetaVault.addStrategies(strategies);

        IBaseVault[] memory strategiesToRemove = new IBaseVault[](1);
        strategiesToRemove[0] = cryticCashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.removeStrategies(strategies, erc4626StrategyVault);
    }

    function test_SizeMetaVault_removeStrategies() public {
        _deposit(alice, sizeMetaVault, 100e6);

        uint256 length = sizeMetaVault.strategiesCount();
        IBaseVault[] memory currentStrategies = new IBaseVault[](length);
        currentStrategies = _getStrategies(sizeMetaVault);

        for (uint256 i = 0; i < currentStrategies.length; i++) {
            uint256 strategyAssets = currentStrategies[i].totalAssets();
            vm.prank(strategist);
            sizeMetaVault.rebalance(currentStrategies[i], currentStrategies[(i + 1) % length], strategyAssets / 2, 0);
        }

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = cryticCashStrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        IBaseVault[] memory strategiesToRemove = new IBaseVault[](currentStrategies.length);
        for (uint256 i = 0; i < currentStrategies.length; i++) {
            strategiesToRemove[i] = IBaseVault(currentStrategies[i]);
        }

        vm.startPrank(strategist);
        sizeMetaVault.removeStrategies(strategiesToRemove, cryticCashStrategyVault);

        uint256 removeStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.removeStrategies.selector).duration;
        vm.warp(block.timestamp + removeStrategiesTimelockDuration);

        sizeMetaVault.removeStrategies(strategiesToRemove, cryticCashStrategyVault);

        sizeMetaVault.removeStrategies(strategies, cryticCashStrategyVault);
        vm.warp(block.timestamp + removeStrategiesTimelockDuration);

        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.removeStrategies(strategies, cryticCashStrategyVault);
        vm.stopPrank();

        for (uint256 i = 0; i < strategiesToRemove.length; i++) {
            assertGt(strategiesToRemove[i].totalAssets(), 0);
        }
    }

    function test_SizeMetaVault_removeStrategies_invalid_strategy_must_revert() public {
        IBaseVault[] memory strategiesToRemove = new IBaseVault[](1);
        strategiesToRemove[0] = cryticCashStrategyVault;

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.removeStrategies(strategiesToRemove, cashStrategyVault);
    }

    function test_SizeMetaVault_deposit_withdraw() public {
        uint256 initialTotalAssets = sizeMetaVault.totalAssets();

        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), depositAmount);

        vm.prank(alice);
        sizeMetaVault.deposit(depositAmount, alice);

        vm.prank(alice);
        sizeMetaVault.withdraw(depositAmount - 1, alice, alice);

        assertEq(sizeMetaVault.balanceOf(alice), 0);
        assertEq(sizeMetaVault.totalAssets(), initialTotalAssets + 1);
        assertEq(erc20Asset.balanceOf(alice), depositAmount - 1);
    }

    function test_SizeMetaVault_deposit_deposit_withdraw() public {
        uint256 initialTotalAssets = sizeMetaVault.totalAssets();

        uint256 firstDepositAmount = 100e6;
        uint256 secondDepositAmount = 50e6;
        _mint(erc20Asset, alice, firstDepositAmount + secondDepositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), firstDepositAmount + secondDepositAmount);

        vm.startPrank(alice);
        sizeMetaVault.deposit(firstDepositAmount, alice);
        sizeMetaVault.deposit(secondDepositAmount, alice);
        vm.stopPrank();

        vm.startPrank(alice);
        sizeMetaVault.withdraw(firstDepositAmount, alice, alice);
        sizeMetaVault.withdraw(secondDepositAmount - 1, alice, alice);
        vm.stopPrank();

        assertEq(sizeMetaVault.balanceOf(alice), 0);
        assertEq(sizeMetaVault.totalAssets(), initialTotalAssets + 1);
        assertEq(erc20Asset.balanceOf(alice), firstDepositAmount + secondDepositAmount - 1);
    }

    function test_SizeMetaVault_deposit_redeem() public {
        uint256 initialTotalAssets = sizeMetaVault.totalAssets();

        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), depositAmount);

        vm.prank(alice);
        sizeMetaVault.deposit(depositAmount, alice);

        uint256 shares = sizeMetaVault.balanceOf(alice);

        vm.prank(alice);
        sizeMetaVault.redeem(shares, alice, alice);

        assertEq(sizeMetaVault.balanceOf(alice), 0);
        assertEq(sizeMetaVault.totalAssets(), initialTotalAssets + 1);
        assertEq(erc20Asset.balanceOf(alice), depositAmount - 1);
    }

    ////////////////////////////////////////////
    // Customized Vault for ERC4626StrategyVault was used to hit specific edge cases
    ///////////////////////////////////////////

    function _deploy_new_ERC4626StrategyVault(VaultType vaultType)
        private
        returns (ERC4626StrategyVault newERC4626StrategyVault)
    {
        ERC4626StrategyVaultScript deployer = new ERC4626StrategyVaultScript();

        _mint(erc20Asset, address(deployer), FIRST_DEPOSIT_AMOUNT);

        if (vaultType == VaultType.REVERT_ON_DEPOSIT) {
            vault_revertDeposit = new VaultMockRevertOnDeposit(bob, erc20Asset, "VaultMockRevertOnDeposit", "VMO");
            vm.label(address(vault_revertDeposit), "VaultMockRevertOnDeposit");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_revertDeposit);
        } else if (vaultType == VaultType.REVERT_ON_WITHDRAW) {
            vault_revertWithdraw = new VaultMockRevertOnWithdraw(bob, erc20Asset, "VaultMockRevertOnWithdraw", "VMO");
            vm.label(address(vault_revertWithdraw), "VaultMockRevertOnWithdraw");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_revertWithdraw);
        } else if (vaultType == VaultType.ASSET_FEE_ON_WITHDRAW) {
            vault_assetFeeOnWithdraw =
                new VaultMockAssetFeeOnWithdraw(bob, erc20Asset, "VaultMockAssetFeeOnWithdraw", "VMO");
            vm.label(address(vault_assetFeeOnWithdraw), "VaultMockAssetFeeOnWithdraw");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_assetFeeOnWithdraw);
        } else {
            revert("Invalid vault type");
        }
        vm.label(address(newERC4626StrategyVault), "NewERC4626StrategyVault");

        IBaseVault[] memory oldStrategies = _getStrategies(sizeMetaVault);
        IBaseVault[] memory newStrategies = new IBaseVault[](1);
        newStrategies[0] = newERC4626StrategyVault;

        vm.prank(strategist);
        sizeMetaVault.addStrategies(newStrategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);
        vm.prank(strategist);
        sizeMetaVault.addStrategies(newStrategies);

        IBaseVault[] memory strategiesToRemove = new IBaseVault[](oldStrategies.length);
        for (uint256 i = 0; i < oldStrategies.length; i++) {
            strategiesToRemove[i] = IBaseVault(oldStrategies[i]);
        }

        vm.prank(admin);
        sizeMetaVault.removeStrategies(strategiesToRemove, newERC4626StrategyVault);

        return newERC4626StrategyVault;
    }

    function test_SizeMetaVault_deposit_revert_if_all_assets_cannot_be_deposited() public {
        _deploy_new_ERC4626StrategyVault(VaultType.REVERT_ON_DEPOSIT);

        // now, only on strategy with customized maxDeposit that is not type(uint256).max

        _mint(erc20Asset, alice, type(uint256).max);
        _approve(alice, erc20Asset, address(sizeMetaVault), type(uint256).max);

        vm.prank(bob);
        vault_revertDeposit.setRevertOnDeposit(true);

        uint256 shares = sizeMetaVault.previewDeposit(type(uint32).max);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SizeMetaVault.CannotDepositToStrategies.selector, type(uint32).max, shares, type(uint32).max
            )
        );
        sizeMetaVault.deposit(type(uint32).max, alice);
    }

    function test_SizeMetaVault_withdraw_revert_if_all_assets_cannot_be_withdrawn() public {
        _deploy_new_ERC4626StrategyVault(VaultType.REVERT_ON_WITHDRAW);

        uint256 amount = 100e6;

        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(sizeMetaVault), amount);

        vm.prank(alice);
        sizeMetaVault.deposit(amount, alice);

        uint256 withdrawableAssets = sizeMetaVault.maxWithdraw(alice);
        uint256 shares = sizeMetaVault.previewWithdraw(withdrawableAssets);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SizeMetaVault.CannotWithdrawFromStrategies.selector, withdrawableAssets, shares, withdrawableAssets
            )
        );
        sizeMetaVault.withdraw(withdrawableAssets, alice, alice);
    }

    function test_SizeMetaVault_withdraw_does_not_revert_if_asset_fee_on_withdraw() public {
        IBaseVault newStrategy = _deploy_new_ERC4626StrategyVault(VaultType.ASSET_FEE_ON_WITHDRAW);

        uint256 depositAmount = 1000e6;

        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), depositAmount);

        vm.prank(alice);
        sizeMetaVault.deposit(depositAmount, alice);

        uint256 withdrawAmount = 100e6;
        uint256 withdrawFee =
            withdrawAmount * vault_assetFeeOnWithdraw.ASSET_FEE_PERCENT() / vault_assetFeeOnWithdraw.PERCENT();
        uint256 shares = sizeMetaVault.previewWithdraw(withdrawAmount);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SizeMetaVault.CannotWithdrawFromStrategies.selector, withdrawAmount, shares, withdrawFee
            )
        );
        sizeMetaVault.withdraw(withdrawAmount, alice, alice);

        IBaseVault[] memory strategies = new IBaseVault[](1);
        strategies[0] = cashStrategyVault;
        vm.prank(admin);
        sizeMetaVault.addStrategies(strategies);

        vm.prank(strategist);
        sizeMetaVault.rebalance(newStrategy, cashStrategyVault, depositAmount / 2, 0);

        vm.prank(alice);
        sizeMetaVault.withdraw(withdrawAmount, alice, alice);

        assertGt(sizeMetaVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }

    function test_SizeMetaVault_addStrategies_max_strategies_exceeded() public {
        ERC4626StrategyVaultScript deployer = new ERC4626StrategyVaultScript();
        IBaseVault[] memory strategies = new IBaseVault[](10);
        for (uint256 i = 0; i < strategies.length; i++) {
            ERC4626Mock vault = new ERC4626Mock(address(erc20Asset));
            _mint(erc20Asset, address(deployer), FIRST_DEPOSIT_AMOUNT);
            strategies[i] = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault);
        }

        vm.prank(strategist);
        sizeMetaVault.addStrategies(strategies);

        uint256 addStrategiesTimelockDuration =
            sizeMetaVault.getTimelockData(sizeMetaVault.addStrategies.selector).duration;
        vm.warp(block.timestamp + addStrategiesTimelockDuration);

        uint256 maxStrategies = sizeMetaVault.MAX_STRATEGIES();

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.MaxStrategiesExceeded.selector, maxStrategies + 1, maxStrategies)
        );
        sizeMetaVault.addStrategies(strategies);
    }

    function test_SizeMetaVault_maxWithdraw_cannot_be_used_to_steal_assets() public {
        _deposit(alice, sizeMetaVault, 100e6);
        _deposit(bob, sizeMetaVault, 200e6);

        uint256 maxWithdraw = sizeMetaVault.maxWithdraw(alice);

        vm.expectRevert(
            abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, alice, 150e6, maxWithdraw)
        );
        _withdraw(alice, sizeMetaVault, 150e6);
    }
}
