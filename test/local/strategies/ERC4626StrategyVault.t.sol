// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {ERC4626Mock} from "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Auth} from "@src/Auth.sol";
import {IVault} from "@src/IVault.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {VaultMock} from "@test/mocks/VaultMock.t.sol";

import {console3} from "console3/console3.sol";
import {console} from "forge-std/console.sol";

contract ERC4626StrategyVaultTest is BaseTest, Initializable {
    uint256 initialBalance;
    uint256 initialTotalAssets;
    uint256 _delta_ = 1;

    function setUp() public override {
        super.setUp();
        initialTotalAssets = erc4626StrategyVault.totalAssets();
        initialBalance = erc20Asset.balanceOf(address(erc4626Vault));
    }

    function test_ERC4626StrategyVault_deposit_balanceOf_totalAssets() public {
        uint256 amount = 100e6;
        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), amount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(amount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), amount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + amount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + amount);
        assertEq(erc20Asset.balanceOf(alice), 0);
    }

    function test_ERC4626StrategyVault_deposit_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount);
        assertEq(erc20Asset.balanceOf(alice), 0);

        uint256 withdrawAmount = 30e6;
        vm.prank(alice);
        erc4626StrategyVault.withdraw(withdrawAmount, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(erc4626StrategyVault.totalAssets(), initialTotalAssets + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(address(erc4626Vault)), initialBalance + depositAmount - withdrawAmount);
        assertEq(erc20Asset.balanceOf(alice), withdrawAmount);
    }

    function test_ERC4626StrategyVault_deposit_rebalance_does_not_change_balanceOf() public {
        IVault[] memory strategies = new IVault[](3);
        strategies[0] = erc4626StrategyVault;
        strategies[1] = cashStrategyVault;
        strategies[2] = aaveStrategyVault;
        vm.prank(strategist);
        veryLiquidVault.reorderStrategies(strategies);

        _deposit(charlie, veryLiquidVault, 100e6);

        uint256 balanceBeforeERC4626StrategyVault = erc20Asset.balanceOf(address(erc4626Vault));

        uint256 depositAmount = 200e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 balanceBeforeRebalance = erc20Asset.balanceOf(address(cashStrategyVault));

        uint256 pullAmount = 30e6;
        vm.prank(strategist);
        veryLiquidVault.rebalance(erc4626StrategyVault, cashStrategyVault, pullAmount, 0.01e18);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(
            erc20Asset.balanceOf(address(erc4626Vault)), balanceBeforeERC4626StrategyVault + depositAmount - pullAmount
        );
        assertEq(erc20Asset.balanceOf(address(cashStrategyVault)), balanceBeforeRebalance + pullAmount);
    }

    function test_ERC4626StrategyVault_deposit_rebalance_redeem() public {
        IVault[] memory strategies = new IVault[](3);
        strategies[0] = erc4626StrategyVault;
        strategies[1] = cashStrategyVault;
        strategies[2] = aaveStrategyVault;
        vm.prank(strategist);
        veryLiquidVault.reorderStrategies(strategies);

        _deposit(charlie, veryLiquidVault, 100e6);

        uint256 balanceBeforeERC4626StrategyVault = erc20Asset.balanceOf(address(erc4626Vault));

        uint256 depositAmount = 200e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 balanceBeforeRebalance = erc20Asset.balanceOf(address(cashStrategyVault));

        uint256 pullAmount = 30e6;
        vm.prank(strategist);
        veryLiquidVault.rebalance(erc4626StrategyVault, cashStrategyVault, pullAmount, 0.01e18);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(
            erc20Asset.balanceOf(address(erc4626Vault)), balanceBeforeERC4626StrategyVault + depositAmount - pullAmount
        );
        assertEq(erc20Asset.balanceOf(address(cashStrategyVault)), balanceBeforeRebalance + pullAmount);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);

        vm.prank(alice);
        erc4626StrategyVault.redeem(shares, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }

    function test_ERC4626StrategyVault_deposit_donate_withdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(shares);

        vm.prank(alice);
        erc4626StrategyVault.withdraw(previewRedeemAssets, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 0);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }

    function test_ERC4626StrategyVault_deposit_donate_redeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        uint256 maxRedeem = erc4626StrategyVault.maxRedeem(alice);
        uint256 previewRedeemAssets = erc4626StrategyVault.previewRedeem(maxRedeem);

        vm.prank(alice);
        erc4626StrategyVault.redeem(maxRedeem, alice, alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), 1);
        assertEq(erc20Asset.balanceOf(alice), previewRedeemAssets);
    }

    function test_ERC4626StrategyVault_initialize_with_zero_address_auth_must_revert() public {
        VaultMock vaultMock = new VaultMock(alice, erc20Asset, "VAULTMOCK", "VM");
        _mint(erc20Asset, alice, FIRST_DEPOSIT_AMOUNT);

        address ERC4626StrategyVaultImplementation = address(new ERC4626StrategyVault());

        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        vm.prank(alice);
        ERC4626StrategyVault(
            payable(
                new ERC1967Proxy(
                    ERC4626StrategyVaultImplementation,
                    abi.encodeCall(
                        ERC4626StrategyVault.initialize,
                        (Auth(address(0)), "VAULT", "VAULT", address(this), FIRST_DEPOSIT_AMOUNT, vaultMock)
                    )
                )
            )
        );
    }

    function test_ERC4626StrategyVault_initialize_with_zero_first_amount_to_deposit_must_revert() public {
        VaultMock vaultMock = new VaultMock(alice, erc20Asset, "VAULTMOCK", "VM");

        address AuthImplementation = address(new Auth());
        Auth auth =
            Auth(payable(new ERC1967Proxy(AuthImplementation, abi.encodeWithSelector(Auth.initialize.selector, bob))));

        address ERC4626StrategyVaultImplementation = address(new ERC4626StrategyVault());

        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAmount.selector));
        vm.prank(alice);
        ERC4626StrategyVault(
            payable(
                new ERC1967Proxy(
                    ERC4626StrategyVaultImplementation,
                    abi.encodeCall(
                        ERC4626StrategyVault.initialize, (auth, "VAULT", "VAULT", address(this), 0, vaultMock)
                    )
                )
            )
        );
    }

    function test_ERC4626StrategyVault_initialize_with_zero_address_vault_must_revert() public {
        _mint(erc20Asset, alice, FIRST_DEPOSIT_AMOUNT);

        address AuthImplementation = address(new Auth());
        Auth auth =
            Auth(payable(new ERC1967Proxy(AuthImplementation, abi.encodeWithSelector(Auth.initialize.selector, bob))));

        _mint(erc20Asset, alice, FIRST_DEPOSIT_AMOUNT);

        address ERC4626StrategyVaultImplementation = address(new ERC4626StrategyVault());

        vm.expectRevert(abi.encodeWithSelector(BaseVault.NullAddress.selector));
        vm.prank(alice);
        ERC4626StrategyVault(
            payable(
                new ERC1967Proxy(
                    ERC4626StrategyVaultImplementation,
                    abi.encodeCall(
                        ERC4626StrategyVault.initialize,
                        (auth, "VAULT", "VAULT", address(this), FIRST_DEPOSIT_AMOUNT, VaultMock(address(0)))
                    )
                )
            )
        );
    }

    function test_ERC4626StrategyVault_maxDeposit() public {
        address dummy = makeAddr("dummy");
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        assertEq(
            erc4626StrategyVault.vault().maxDeposit(address(erc4626StrategyVault)),
            erc4626StrategyVault.maxDeposit(dummy)
        );

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        assertEq(
            erc4626StrategyVault.vault().maxDeposit(address(erc4626StrategyVault)),
            erc4626StrategyVault.maxDeposit(dummy)
        );
    }

    function test_ERC4626StrategyVault_maxMint() public {
        address dummy = makeAddr("dummy");
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        assertEq(
            erc4626StrategyVault.vault().maxMint(address(erc4626StrategyVault)), erc4626StrategyVault.maxMint(dummy)
        );

        uint256 donation = 30e6;
        _mint(erc20Asset, bob, donation);
        vm.prank(bob);
        erc20Asset.transfer(address(erc4626Vault), donation);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);
        assertEq(erc4626StrategyVault.balanceOf(bob), 0);

        assertEq(
            erc4626StrategyVault.vault().maxMint(address(erc4626StrategyVault)), erc4626StrategyVault.maxMint(dummy)
        );
    }

    function test_ERC4626StrategyVault_maxWithdraw() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        assertEq(erc4626StrategyVault.convertToAssets(shares), erc4626StrategyVault.maxWithdraw(alice));

        uint256 depositAmount2 = 50e6;
        _mint(erc20Asset, bob, depositAmount2);
        _approve(bob, erc20Asset, address(erc4626StrategyVault), depositAmount2);
        vm.prank(bob);
        erc4626StrategyVault.deposit(depositAmount2, bob);
        uint256 shares2 = erc4626StrategyVault.balanceOf(bob);
        assertEq(erc4626StrategyVault.balanceOf(bob), shares2);

        assertEq(erc4626StrategyVault.convertToAssets(shares2), erc4626StrategyVault.maxWithdraw(bob));

        uint256 maxWithdrawAlice = erc4626StrategyVault.maxWithdraw(alice);
        uint256 maxWithdrawBob = erc4626StrategyVault.maxWithdraw(bob);
        uint256 maxWithdrawSelf = erc4626StrategyVault.maxWithdraw(address(erc4626StrategyVault));
        uint256 maxWithdrawVeryLiquidVault = erc4626StrategyVault.maxWithdraw(address(veryLiquidVault));
        uint256 maxWithdrawVault = erc4626StrategyVault.vault().maxWithdraw(address(erc4626StrategyVault));

        assertEq(maxWithdrawAlice + maxWithdrawBob + maxWithdrawVeryLiquidVault + maxWithdrawSelf, maxWithdrawVault);

        uint256 burnAmount = (depositAmount + depositAmount2) / 2;
        _burn(erc20Asset, address(erc4626StrategyVault.vault()), burnAmount);

        uint256 prevAliceMaxWithdraw = erc4626StrategyVault.maxWithdraw(alice);
        uint256 prevBobMaxWithdraw = erc4626StrategyVault.maxWithdraw(bob);

        assertEq(erc4626StrategyVault.convertToAssets(shares), prevAliceMaxWithdraw);
        assertEq(erc4626StrategyVault.convertToAssets(shares2), prevBobMaxWithdraw);

        _mint(erc20Asset, address(erc4626Vault), depositAmount);

        uint256 maxWithdrawAliceAfter = erc4626StrategyVault.maxWithdraw(alice);
        uint256 maxWithdrawBobAfter = erc4626StrategyVault.maxWithdraw(bob);
        uint256 maxWithdrawSelfAfter = erc4626StrategyVault.maxWithdraw(address(erc4626StrategyVault));
        uint256 maxWithdrawVeryLiquidVaultAfter = erc4626StrategyVault.maxWithdraw(address(veryLiquidVault));
        uint256 maxWithdrawVaultAfter = erc4626StrategyVault.vault().maxWithdraw(address(erc4626StrategyVault));

        assertLe(
            maxWithdrawAliceAfter + maxWithdrawBobAfter + maxWithdrawVeryLiquidVaultAfter + maxWithdrawSelfAfter,
            maxWithdrawVaultAfter
        );
        assertApproxEqAbs(
            maxWithdrawAliceAfter + maxWithdrawBobAfter + maxWithdrawVeryLiquidVaultAfter + maxWithdrawSelfAfter,
            maxWithdrawVaultAfter,
            10
        );
    }

    function test_ERC4626StrategyVault_maxRedeem() public {
        uint256 depositAmount = 100e6;
        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), depositAmount);
        vm.prank(alice);
        erc4626StrategyVault.deposit(depositAmount, alice);
        uint256 shares = erc4626StrategyVault.balanceOf(alice);
        assertEq(erc4626StrategyVault.balanceOf(alice), shares);

        assertEq(erc4626StrategyVault.balanceOf(alice), erc4626StrategyVault.maxRedeem(alice));

        uint256 depositAmount2 = 50e6;
        _mint(erc20Asset, bob, depositAmount2);
        _approve(bob, erc20Asset, address(erc4626StrategyVault), depositAmount2);
        vm.prank(bob);
        erc4626StrategyVault.deposit(depositAmount2, bob);
        uint256 shares2 = erc4626StrategyVault.balanceOf(bob);
        assertEq(erc4626StrategyVault.balanceOf(bob), shares2);

        assertEq(erc4626StrategyVault.balanceOf(bob), erc4626StrategyVault.maxRedeem(bob));

        uint256 burnAmount = (depositAmount + depositAmount2) / 2;
        _burn(erc20Asset, address(erc4626StrategyVault.vault()), burnAmount);

        assertGe(erc4626StrategyVault.balanceOf(alice), erc4626StrategyVault.maxRedeem(alice));
        assertApproxEqAbs(erc4626StrategyVault.balanceOf(alice), erc4626StrategyVault.maxRedeem(alice), 2);
        assertGe(erc4626StrategyVault.balanceOf(bob), erc4626StrategyVault.maxRedeem(bob));
        assertApproxEqAbs(erc4626StrategyVault.balanceOf(bob), erc4626StrategyVault.maxRedeem(bob), 2);
    }

    function test_ERC4626StrategyVault_totalAssetsCap_maxDeposit_maxMint() public {
        uint256 totalAssetsBefore = erc4626StrategyVault.totalAssets();
        uint256 underlyingVaultCap = 100e6;

        vm.mockCall(
            address(erc4626StrategyVault.vault()),
            abi.encodeCall(erc4626StrategyVault.vault().maxDeposit, (address(erc4626StrategyVault))),
            abi.encode(underlyingVaultCap)
        );
        vm.mockCall(
            address(erc4626StrategyVault.vault()),
            abi.encodeCall(erc4626StrategyVault.vault().maxMint, (address(erc4626StrategyVault))),
            abi.encode(underlyingVaultCap)
        );

        assertEq(erc4626StrategyVault.maxDeposit(address(alice)), underlyingVaultCap);
        assertEq(erc4626StrategyVault.maxMint(address(alice)), underlyingVaultCap);

        uint256 totalAssetsCap = 30e6;
        vm.prank(admin);
        erc4626StrategyVault.setTotalAssetsCap(totalAssetsCap);

        assertEq(erc4626StrategyVault.maxDeposit(address(alice)), Math.saturatingSub(totalAssetsCap, totalAssetsBefore));
        assertEq(erc4626StrategyVault.maxMint(address(alice)), Math.saturatingSub(totalAssetsCap, totalAssetsBefore));
    }

    function test_ERC4626StrategyVault_maxWithdraw_maxRedeem() public {
        uint256 assetsBefore =
            erc4626StrategyVault.convertToAssets(erc4626StrategyVault.balanceOf(address(veryLiquidVault)));
        IVault[] memory strategies = new IVault[](3);
        strategies[0] = erc4626StrategyVault;
        strategies[1] = cashStrategyVault;
        strategies[2] = aaveStrategyVault;
        vm.prank(strategist);
        veryLiquidVault.reorderStrategies(strategies);

        _deposit(alice, erc4626StrategyVault, 100e6);
        _deposit(bob, veryLiquidVault, 30e6);

        uint256 depositedToVault = strategies[0] == erc4626StrategyVault ? 30e6 : 0;

        assertEq(erc4626StrategyVault.maxWithdraw(address(veryLiquidVault)), assetsBefore + depositedToVault);
        assertEq(
            erc4626StrategyVault.maxRedeem(address(veryLiquidVault)),
            erc4626StrategyVault.previewRedeem(assetsBefore + depositedToVault)
        );
    }

    function test_ERC4626StrategyVault_max_same_units() public {
        uint256 assets = 100e6;
        _deposit(alice, erc4626StrategyVault, assets);
        _mint(erc20Asset, address(erc4626StrategyVault.vault()), 50e6);
        deal(address(erc4626StrategyVault.vault()), address(erc4626StrategyVault), 10e6);

        uint256 shares = erc4626StrategyVault.balanceOf(address(alice));

        assertLe(erc4626StrategyVault.maxRedeem(address(alice)), shares);
        assertApproxEqAbs(erc4626StrategyVault.maxRedeem(address(alice)), shares, 100);
    }

    function testFuzz_ERC4626StrategyVault_deposit_assets_shares_0_reverts(uint256 amount) public {
        amount = bound(amount, 1, 100e6);

        _mint(erc20Asset, address(erc4626StrategyVault.vault()), amount * 2);

        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(erc4626StrategyVault), amount);

        vm.prank(alice);
        try erc4626StrategyVault.deposit(amount, alice) {
            _mint(erc20Asset, address(erc4626StrategyVault.vault()), amount / 10);

            uint256 maxRedeem = erc4626StrategyVault.maxRedeem(alice);
            vm.assume(maxRedeem >= 1);

            vm.prank(alice);
            try erc4626StrategyVault.redeem(1, alice, alice) {}
            catch (bytes memory err) {
                assertEq(bytes4(err), BaseVault.NullAmount.selector);
            }
        } catch (bytes memory err) {
            assertEq(bytes4(err), BaseVault.NullAmount.selector);
        }
    }

    function test_ERC4626StrategyVault_deposit_assets_shares_0_reverts_concrete_01() public {
        testFuzz_ERC4626StrategyVault_deposit_assets_shares_0_reverts(
            1_108_790_381_926_929_861_836_164_074_425_007_624_709_311_183_104_891_332_381_950_016_717_928_201
        );
    }

    function test_ERC4626StrategyVault_rescueTokens_cannot_drain_vault() public {
        uint256 totalAssetsStart = erc4626StrategyVault.totalAssets();

        uint256 amount = 100e6;
        IERC4626 vault = erc4626StrategyVault.vault();
        deal(address(erc20Asset), address(vault), amount);

        uint256 totalAssetsBefore = erc4626StrategyVault.totalAssets();
        assertGt(totalAssetsBefore, 0);
        assertGt(totalAssetsBefore, totalAssetsStart);

        vm.prank(guardian);
        vm.expectRevert(abi.encodeWithSelector(BaseVault.InvalidAsset.selector, address(vault)));
        erc4626StrategyVault.rescueTokens(address(vault), address(guardian));

        assertEq(erc4626StrategyVault.totalAssets(), totalAssetsBefore);
    }

    function testFuzz_ERC4626StrategyVault_withdraw_loss_socialization(
        uint256 aliceDeposit,
        uint256 bobDeposit,
        uint256 lossAmount
    ) public {
        _setupSimpleConfiguration();

        // Bound inputs to reasonable ranges
        aliceDeposit = bound(aliceDeposit, 10e6, 1000e6); // 10 to 1000 USDC
        bobDeposit = bound(bobDeposit, 10e6, 1000e6);
        lossAmount = bound(lossAmount, 1e6, (aliceDeposit + bobDeposit) / 2); // 1 to 50% loss

        address[] memory accounts = new address[](3);
        accounts[0] = address(alice);
        accounts[1] = address(bob);
        accounts[2] = address(erc4626StrategyVault);
        console.log("Initial state:");
        console3.logERC4626(address(erc4626StrategyVault), accounts);

        // Setup: Alice and Bob deposit
        _deposit(alice, erc4626StrategyVault, aliceDeposit);
        _deposit(bob, erc4626StrategyVault, bobDeposit);
        uint256 bobShares = erc4626StrategyVault.balanceOf(bob);
        console.log("After deposits:");
        console3.logERC4626(address(erc4626StrategyVault), accounts);

        // Simulate loss in underlying vault
        _burn(erc20Asset, address(erc4626Vault), lossAmount);
        console.log("After loss:");
        console3.logERC4626(address(erc4626StrategyVault), accounts);

        // THE INVARIANT: Record Bob's value BEFORE Alice withdraws
        uint256 bobValueBefore = erc4626StrategyVault.convertToAssets(bobShares);

        // Alice withdraws
        uint256 aliceMaxWithdraw = erc4626StrategyVault.maxWithdraw(alice);
        vm.assume(aliceMaxWithdraw > 0);

        vm.prank(alice);
        erc4626StrategyVault.withdraw(aliceMaxWithdraw, alice, alice);
        console.log("After withdrawal:");
        console3.logERC4626(address(erc4626StrategyVault), accounts);

        // Check Bob's value AFTER Alice withdraws
        uint256 bobValueAfter = erc4626StrategyVault.convertToAssets(bobShares);

        // THE TEST: Bob's value should NOT change when Alice withdraws
        assertGe(
            bobValueAfter + _delta_, bobValueBefore, "Alice's withdrawal reduced Bob's assets (loss socialization)"
        );
    }

    function test_ERC4626StrategyVault_withdraw_loss_socialization_exact_concrete_01() public {
        // set _delta_ to 0 to see it fail
        _delta_ = 1;
        testFuzz_ERC4626StrategyVault_withdraw_loss_socialization(962418865, 10000000, 136802347);
    }
}
