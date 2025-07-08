// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {console} from "forge-std/console.sol";
import {VaultMockCustomized} from "@test/mocks/VaultMockCustomized.t.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {Auth, SIZE_VAULT_ROLE} from "@src/Auth.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SizeMetaVaultTest is BaseTest {
    function test_SizeMetaVault_initialize() public view {
        assertEq(address(sizeMetaVault.asset()), address(erc20Asset));
        assertEq(sizeMetaVault.name(), string.concat("Size ", erc20Asset.name(), " Vault"));
        assertEq(sizeMetaVault.symbol(), string.concat("size", erc20Asset.symbol()));
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
        assertEq(sizeMetaVault.totalSupply(), sizeMetaVault.strategiesCount() * FIRST_DEPOSIT_AMOUNT + 1);
        assertEq(sizeMetaVault.balanceOf(address(this)), 0);
        assertEq(sizeMetaVault.allowance(address(this), address(this)), 0);
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
        assertEq(sizeMetaVault.decimals(), erc20Asset.decimals());
    }

    /// rebalance ///

    function test_SizeMetaVault_rebalance_cashStrategy_to_erc4626() public {
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 cashStrategyDeadAssetsBefore = cashStrategyVault.deadAssets();

        uint256 amount = cashAssetsBefore - cashStrategyDeadAssetsBefore;

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount);

        uint256 cashAssetsAfter = cashStrategyVault.totalAssets();
        uint256 erc4626AssetsAfter = erc4626StrategyVault.totalAssets();
        uint256 cashStrategyDeadAssetsAfter = cashStrategyVault.deadAssets();

        assertEq(cashAssetsAfter, cashStrategyDeadAssetsAfter);
        assertEq(cashStrategyDeadAssetsBefore, cashStrategyDeadAssetsAfter);
        assertEq(erc4626AssetsAfter, erc4626AssetsBefore + amount);
    }

    function test_SizeMetaVault_rebalance_erc4626_to_cashStrategy() public {
        uint256 erc4626AssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 cashAssetsBefore = cashStrategyVault.totalAssets();
        uint256 erc4626StrategyDeadAssetsBefore = cashStrategyVault.deadAssets();

        uint256 amount = erc4626AssetsBefore - erc4626StrategyDeadAssetsBefore;

        vm.prank(strategist);
        sizeMetaVault.rebalance(erc4626StrategyVault, cashStrategyVault, amount);

        uint256 erc4626AssetsAfter = erc4626StrategyVault.totalAssets();
        uint256 cashAssetsAfter = cashStrategyVault.totalAssets();
        uint256 erc4626StrategyDeadAssetsAfter = cashStrategyVault.deadAssets();

        assertEq(erc4626AssetsAfter, erc4626StrategyDeadAssetsAfter);
        assertEq(erc4626StrategyDeadAssetsBefore, erc4626StrategyDeadAssetsAfter);
        assertEq(cashAssetsAfter, cashAssetsBefore + amount);
    }

    function test_SizeMetaVault_rebalance_revert_if_insufficient_assets() public {
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
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, amount);

        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, 5e6);
        assertEq(cashStrategyVault.totalAssets(), cashAssetsBefore - 5e6);
        assertEq(erc4626StrategyVault.totalAssets(), erc4626AssetsBefore + 5e6);
    }

    function test_sizeMetaVault_rebalance_strategyFrom_not_added_must_revert() public {
        // remove cashStrategyVault; check removal; try to transfer from it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        vm.prank(strategist);
        sizeMetaVault.removeStrategy(address(cashStrategyVault));

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(cashStrategyVault)));
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, cashAssets);
    }

    function test_sizeMetaVault_rebalance_strategyTo_not_added_must_revert() public {
        // remove erc4626StrategyVault; check removal; try to transfer to it
        uint256 lengthBefore = sizeMetaVault.strategiesCount();
        uint256 cashAssets = cashStrategyVault.totalAssets();

        vm.prank(strategist);
        sizeMetaVault.removeStrategy(address(erc4626StrategyVault));

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        assertEq(lengthBefore - 1, lengthAfter);

        vm.expectRevert(abi.encodeWithSelector(SizeMetaVault.InvalidStrategy.selector, address(erc4626StrategyVault)));
        vm.prank(strategist);
        sizeMetaVault.rebalance(cashStrategyVault, erc4626StrategyVault, cashAssets);
    }

    /// setStrategies  ///

    function test_SizeMetaVault_setStrategies() public {
        address firstStrategy = makeAddr("firstStrategy");
        address secondStrategy = makeAddr("secondStrategy");
        address thirdStrategy = makeAddr("thirdStrategy");

        address[] memory strategies = new address[](3);
        strategies[0] = firstStrategy;
        strategies[1] = secondStrategy;
        strategies[2] = thirdStrategy;

        vm.prank(strategist);
        sizeMetaVault.setStrategies(strategies);

        vm.assertEq(sizeMetaVault.getStrategy(0), firstStrategy);
        vm.assertEq(sizeMetaVault.getStrategy(1), secondStrategy);
        vm.assertEq(sizeMetaVault.getStrategy(2), thirdStrategy);
    }

    /// addStrategy  ///

    function test_SizeMetaVault_addStrategy() public {
        address oneStrategy = makeAddr("oneStrategy");

        uint256 lengthBefore = sizeMetaVault.strategiesCount();

        vm.prank(strategist);
        sizeMetaVault.addStrategy(oneStrategy);

        uint256 lengthAfter = sizeMetaVault.strategiesCount();
        uint256 indexLastStrategy = lengthAfter - 1;

        address lastStrategyAdded = sizeMetaVault.getStrategy(indexLastStrategy);

        vm.assertEq(lengthAfter, lengthBefore + 1);
        vm.assertEq(oneStrategy, lastStrategyAdded);
    }

    // function test_SizeMetaVault_addStrategy_address_zero_must_revert() public {
    //     address addressZero = address(0);

    //     uint256 lengthBefore = sizeMetaVault.strategiesCount();

    //     vm.expectRevert();
    //     vm.prank(strategist);
    //     sizeMetaVault.addStrategy(addressZero);

    //     uint256 lengthAfter = sizeMetaVault.strategiesCount();

    //     assertEq(lengthBefore, lengthAfter);
    // }

    /// removeStrategy  ///

    function test_SizeMetaVault_removeStrategy_one_after_another() public {
        uint256 length = sizeMetaVault.strategiesCount();
        address[] memory currantStrategies = new address[](length);
        currantStrategies = sizeMetaVault.getStrategies();

        vm.startPrank(strategist);
        for (uint256 i = 0; i < length; i++) {
            sizeMetaVault.removeStrategy(currantStrategies[i]);
        }
        vm.stopPrank();
    }

    /// Multi-Function Tests //

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

    //
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

    function _helper_set_local_env() internal returns (ERC4626StrategyVault) {
        VaultMockCustomized vaultMockCustomized = new VaultMockCustomized(bob, erc20Asset, "VAULTMOCKCUSTOMIZED", "VMC");

        _mint(erc20Asset, bob, FIRST_DEPOSIT_AMOUNT);
        _approve(bob, erc20Asset, address(vaultMockCustomized), FIRST_DEPOSIT_AMOUNT);

        address AuthImplementation = address(new Auth());
        Auth auth =
            Auth(payable(new ERC1967Proxy(AuthImplementation, abi.encodeWithSelector(Auth.initialize.selector, bob))));

        address ERC4626StrategyVaultImplementation = address(new ERC4626StrategyVault());
        console.log("y");
        vm.prank(bob);
        ERC4626StrategyVault newERC4626StrategyVault = ERC4626StrategyVault(
            payable(
                new ERC1967Proxy(
                    ERC4626StrategyVaultImplementation,
                    abi.encodeWithSelector(
                        ERC4626StrategyVault.initialize.selector,
                        auth,
                        erc20Asset,
                        "VAULT",
                        "VAULT",
                        FIRST_DEPOSIT_AMOUNT,
                        vaultMockCustomized
                    )
                )
            )
        );
        address[] memory newStrategiesAddresses = new address[](1);
        newStrategiesAddresses[0] = address(newERC4626StrategyVault);

        vm.prank(strategist);
        sizeMetaVault.setStrategies(newStrategiesAddresses);
        return newERC4626StrategyVault;
    }

    // function test_SizeMetaVault_deposit_revert_if_all_assets_cannot_be_deposited() public {
    //     ERC4626StrategyVault newERC4626StrategyVault = _helper_set_local_env();

    //     // now, only on strategy with customized maxDeposit that is not type(uint256).max

    //     _mint(erc20Asset, alice, type(uint128).max);
    //     _approve(alice, erc20Asset, address(sizeMetaVault), type(uint256).max);

    //     uint256 shares = sizeMetaVault.previewDeposit(type(uint128).max);
    //     console.log("x");
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             SizeMetaVault.CannotDepositToStrategies.selector, type(uint128).max, shares, type(uint128).max
    //         )
    //     );
    //     vm.prank(alice);
    //     sizeMetaVault.deposit(type(uint128).max, alice);
    // }

    function test_SizeMetaVault_deposit_in_strategy_fail_must_set_allowance_to_zero() public {}

    function test_SizeMetaVault_withdraw_more_than_assetsToWithdraw_must_revert() public {}
}
