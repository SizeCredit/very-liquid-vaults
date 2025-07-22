// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {Auth, SIZE_VAULT_ROLE} from "@src/Auth.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626StrategyVaultScript} from "@script/ERC4626StrategyVault.s.sol";
import {VaultMockRevertOnDeposit} from "@test/mocks/VaultMockRevertOnDeposit.t.sol";
import {VaultMockDecMaxDeposit} from "@test/mocks/VaultMockDecMaxDeposit.t.sol";
import {VaultMockRevertOnWithdraw} from "@test/mocks/VaultMockRevertOnWithdraw.t.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {console} from "forge-std/console.sol";

contract SizeMetaVaultTest is BaseTest {
    bool public expectRevert = false;

    VaultMockRevertOnDeposit vault_revertDeposit;
    VaultMockRevertOnWithdraw vault_revertWithdraw;
    VaultMockDecMaxDeposit vault_decDeposit;

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
        _deposit(erc4626StrategyVault, alice, 100e6);

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
        IStrategy strategyFrom = cashStrategyVault;
        IStrategy strategyTo = aaveStrategyVault;

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

    function test_SizeMetaVault_addStrategy_validation() public {
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        sizeMetaVault.addStrategy(IStrategy(address(0)));
    }

    function test_SizeMetaVault_removeStrategy_validation() public {
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(0)));
        sizeMetaVault.removeStrategy(IStrategy(address(0)), IStrategy(address(0)));
    }

    function test_SizeMetaVault_reorderStrategies_validation() public {
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.ArrayLengthMismatch.selector, 3, 0));
        sizeMetaVault.reorderStrategies(new IStrategy[](0));

        IStrategy[] memory strategiesWithZero = new IStrategy[](3);
        strategiesWithZero[0] = cryticCashStrategyVault;
        strategiesWithZero[1] = cryticAaveStrategyVault;
        strategiesWithZero[2] = cryticERC4626StrategyVault;

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.reorderStrategies(strategiesWithZero);

        IStrategy[] memory duplicates = new IStrategy[](3);
        duplicates[0] = cashStrategyVault;
        duplicates[1] = erc4626StrategyVault;
        duplicates[2] = cashStrategyVault;

        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cashStrategyVault)));
        sizeMetaVault.reorderStrategies(duplicates);
    }

    function test_SizeMetaVault_rebalance_validation() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 cashStrategyDeadAssets = cashStrategyVault.deadAssets();

        uint256 amount = 5e6;

        // validate strategyFrom
        vm.prank(strategist);
        vm.expectRevert();
        sizeMetaVault.rebalance(IStrategy(address(1)), erc4626StrategyVault, amount, 0);

        // validate strategyTo
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(1)));
        sizeMetaVault.rebalance(cashStrategyVault, IStrategy(address(1)), amount, 0);

        // validate amount 0
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAmount.selector));
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, 0, 0);

        // validate amount > balance
        amount = 50e6;
        assertLt(cashAssetsBefore, amount);

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(
                SizeMetaVault.InsufficientAssets.selector, cashAssetsBefore, cashStrategyDeadAssets, amount
            )
        );
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, 0);
    }

    function test_SizeMetaVault_rebalance() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 cashStrategyDeadAssets = cashStrategyVault.deadAssets();

        uint256 amount = 50e6;
        assertLt(cashAssetsBefore, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                SizeMetaVault.InsufficientAssets.selector, cashAssetsBefore, cashStrategyDeadAssets, amount
            )
        );
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount, 0);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, 5e6, 0);
        assertEq(cashStrategyVault.totalAssets(), cashAssetsBefore - 5e6);
        assertEq(erc4626StrategyVault.totalAssets(), erc4626AssetsBefore + 5e6);
    }

    function test_sizeMetaVault_rebalance_strategyFrom_not_added_must_not_revert() public {
        // remove cashStrategyVault; check removal; try to transfer from it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        vm.prank(strategist);
        sizeMetaVault.removeStrategy(cashStrategyVault, erc4626StrategyVault);

        _mint(erc20Asset, address(cashStrategyVault), 2 * cashAssets);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, cashAssets, 0);
    }

    function test_sizeMetaVault_rebalance_strategyTo_not_added_must_revert() public {
        // remove erc4626StrategyVault; check removal; try to transfer to it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        vm.prank(strategist);
        sizeMetaVault.removeStrategy(erc4626StrategyVault, aaveStrategyVault);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(erc4626StrategyVault)));
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, cashAssets, 0);
    }

    function test_SizeMetaVault_reorderStrategies() public {
        IStrategy firstStrategy = aaveStrategyVault;
        IStrategy secondStrategy = erc4626StrategyVault;
        IStrategy thirdStrategy = cashStrategyVault;

        IStrategy[] memory strategies = new IStrategy[](3);
        strategies[0] = firstStrategy;
        strategies[1] = secondStrategy;
        strategies[2] = thirdStrategy;

        vm.prank(strategist);
        sizeMetaVault.reorderStrategies(strategies);

        assertEq(sizeMetaVault.getStrategy(0), address(firstStrategy));
        assertEq(sizeMetaVault.getStrategy(1), address(secondStrategy));
        assertEq(sizeMetaVault.getStrategy(2), address(thirdStrategy));
    }

    function test_SizeMetaVault_addStrategy() public {
        address oneStrategy = address(cryticCashStrategyVault);

        uint256 lengthBefore = sizeMetaVault.strategiesCount();

        vm.prank(strategist);
        sizeMetaVault.addStrategy(IStrategy(oneStrategy));

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        uint256 indexLastStrategy = lengthAfter - 1;

        address lastStrategyAdded = sizeMetaVault.getStrategy(indexLastStrategy);

        vm.assertEq(lengthAfter, lengthBefore + 1);
        vm.assertEq(oneStrategy, lastStrategyAdded);
    }

    function test_SizeMetaVault_addStrategy_invalid_asset_must_revert() public {
        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cashStrategyVaultWETH)));
        sizeMetaVault.addStrategy(cashStrategyVaultWETH);
    }

    function test_SizeMetaVault_addStrategy_invalid_auth_must_revert() public {
        address invalidAuth = address(0xDEAD);

        vm.mockCall(
            address(cryticCashStrategyVault), abi.encodeWithSelector(IBaseVault.auth.selector), abi.encode(invalidAuth)
        );

        vm.prank(strategist);
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.addStrategy(cryticCashStrategyVault);
    }

    function test_SizeMetaVault_addStrategy_address_zero_must_revert() public {
        address addressZero = address(0);

        uint256 lengthBefore = sizeMetaVault.strategiesCount();

        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        vm.prank(strategist);
        sizeMetaVault.addStrategy(IStrategy(addressZero));

        uint256 lengthAfter = sizeMetaVault.strategiesCount();

        assertEq(lengthBefore, lengthAfter);
    }

    function test_SizeMetaVault_removeStrategy_one_after_another() public {
        uint256 length = sizeMetaVault.strategiesCount();
        address[] memory currentStrategies = new address[](length);
        currentStrategies = sizeMetaVault.getStrategies();

        vm.prank(strategist);
        sizeMetaVault.addStrategy(cryticCashStrategyVault);

        vm.startPrank(strategist);
        for (uint256 i = 0; i < length; i++) {
            IStrategy strategy = IStrategy(currentStrategies[i]);
            sizeMetaVault.removeStrategy(strategy, cryticCashStrategyVault);
        }
        vm.expectRevert(
            abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cryticCashStrategyVault))
        );
        sizeMetaVault.removeStrategy(cryticCashStrategyVault, cryticCashStrategyVault);
        vm.stopPrank();
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

    function _helper_deploy_new_ERC4626StrategyVault(bool _isRevertingOnDeposit, bool _isRevertingOnWithdraw)
        public
        returns (ERC4626StrategyVault)
    {
        ERC4626StrategyVault newERC4626StrategyVault;

        ERC4626StrategyVaultScript deployer = new ERC4626StrategyVaultScript();

        _mint(erc20Asset, address(deployer), FIRST_DEPOSIT_AMOUNT);

        if (_isRevertingOnDeposit) {
            vault_revertDeposit = new VaultMockRevertOnDeposit(bob, erc20Asset, "VAULTMOCKCUSTOMIZED", "VMC");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_revertDeposit);
        } else if (_isRevertingOnWithdraw) {
            vault_revertWithdraw = new VaultMockRevertOnWithdraw(bob, erc20Asset, "VAULTMOCKCUSTOMIZED", "VMC");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_revertWithdraw);
        } else {
            vault_decDeposit = new VaultMockDecMaxDeposit(bob, erc20Asset, "VAULTMOCKCUSTOMIZED", "VMC");
            newERC4626StrategyVault = deployer.deploy(auth, FIRST_DEPOSIT_AMOUNT, vault_decDeposit);
        }
        address[] memory oldStrategies = sizeMetaVault.getStrategies();
        IStrategy[] memory newStrategies = new IStrategy[](1);
        newStrategies[0] = newERC4626StrategyVault;

        for (uint256 i = 0; i < newStrategies.length; i++) {
            vm.prank(strategist);
            sizeMetaVault.addStrategy(newStrategies[i]);
        }

        for (uint256 i = 0; i < oldStrategies.length; i++) {
            IStrategy oldStrategy = IStrategy(oldStrategies[i]);
            vm.prank(strategist);
            sizeMetaVault.removeStrategy(oldStrategy, newERC4626StrategyVault);
        }

        return newERC4626StrategyVault;
    }

    function test_SizeMetaVault_deposit_revert_if_all_assets_cannot_be_deposited() public {
        _helper_deploy_new_ERC4626StrategyVault(true, false);

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
        _helper_deploy_new_ERC4626StrategyVault(false, true);

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

    function test_SizeMetaVault_setMaxStrategies() public {
        vm.prank(admin);
        sizeMetaVault.setMaxStrategies(3);
        assertEq(sizeMetaVault.maxStrategies(), 3);

        vm.prank(strategist);
        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.MaxStrategiesExceeded.selector, 4, 3));
        sizeMetaVault.addStrategy(cryticCashStrategyVault);
    }
}
