// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Test, IMockERC20} from "@a16z/erc4626-tests/ERC4626.test.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Logger} from "@test/Logger.t.sol";
import {console} from "forge-std/Test.sol";

contract ERC4626StrategyVaultERC4626StdTest is ERC4626Test, BaseTest {
    function setUp() public override(ERC4626Test, BaseTest) {
        super.setUp();

        vm.prank(admin);
        Ownable(address(erc20Asset)).transferOwnership(address(this));

        _underlying_ = address(erc20Asset);
        _vault_ = address(erc4626StrategyVault);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }

    function setUpYield(ERC4626Test.Init memory init) public override {
        uint256 balance = erc20Asset.balanceOf(address(erc4626Vault));
        if (init.yield >= 0) {
            // gain
            vm.assume(init.yield < int256(uint256(type(uint128).max)));
            init.yield = bound(init.yield, 0, int256(balance / 100));
            uint256 gain = uint256(init.yield);
            IMockERC20(_underlying_).mint(address(erc4626Vault), gain);
        } else {
            // loss
            vm.assume(init.yield > type(int128).min);
            uint256 loss = uint256(-1 * init.yield);
            vm.assume(loss < balance);
            IMockERC20(_underlying_).burn(address(erc4626Vault), loss);
        }
    }

    function test_ERC4626StrategyVaultERC4626Std_test_RT_redeem_mint_01() public {
        Init memory init = Init({
            user: [
                0x000000000000000000000000000000000000181f,
                0x0000000000000000000000000000000000002d0B,
                0x0000000000000000000000000000000000003dcd,
                0x00000000000000000000000000000000E055fF88
            ],
            share: [uint256(5441), uint256(10097), uint256(8315), uint256(7965)],
            asset: [uint256(1285), uint256(11837), uint256(8952), uint256(4294967294)],
            yield: int256(655649083344436783775280150831979)
        });
        test_RT_redeem_mint(init, 991);
    }

    function _test_ERC4626StrategyVaultERC4626Std_test_RT_withdraw_deposit_01() public {
        Init memory init = Init({
            user: [
                0x00000000000000000000000000000000000030b3,
                0x0000000000000000000000000000000000002367,
                0x0000000000000000000000000000000000001B08,
                0x0000000000000000000000000000000000002D7E
            ],
            share: [uint256(987910862), uint256(587), uint256(13632), uint256(6506)],
            asset: [
                uint256(19744579944030316751180819),
                uint256(1157379602576340765330575612727389539782114060851143049831365),
                uint256(8645),
                uint256(42393604518183400894871284368897910331008433330724914529002052670013337269162)
            ],
            yield: int256(11179)
        });
        uint256 assets = 957625571;

        setUpVault(init);
        console.log("setUpVault");
        _log(init.user);
        address caller = init.user[0];
        assets = bound(assets, 0, _max_withdraw(caller));
        _approve(_underlying_, caller, _vault_, type(uint256).max);
        vm.prank(caller);
        uint256 shares1 = vault_withdraw(assets, caller, caller);
        console.log("withdraw");
        _log(init.user);
        if (!_vaultMayBeEmpty) vm.assume(IERC20(_vault_).totalSupply() > 0);
        vm.prank(caller);
        uint256 shares2 = vault_deposit(assets, caller);
        console.log("deposit");
        _log(init.user);
        assertApproxLeAbs(shares2, shares1, _delta_);
    }

    function test_ERC4626StrategyVaultERC4626Std_test_RT_withdraw_deposit_02() public {
        Init memory init = Init({
            user: [
                0x0000000000000000000000000000000000001DE3,
                0x0000000000000000000000000000000000000618,
                0x0000000000000000000000000000000000000376,
                0x00000000000000000000000000000000C44b11F6
            ],
            share: [uint256(11327), uint256(7386), uint256(5645), uint256(1545)],
            asset: [uint256(3607235850), uint256(795), uint256(1086394138), uint256(15738)],
            yield: int256(11541)
        });
        uint256 assets = 4567;

        setUpVault(init);
        console.log("setUpVault");
        _log(init.user);
        address caller = init.user[0];
        uint256 assetsBefore = vault_convertToAssets(IERC4626(_vault_).balanceOf(caller));
        assets = bound(assets, 0, _max_withdraw(caller));
        _approve(_underlying_, caller, _vault_, type(uint256).max);
        vm.prank(caller);
        uint256 shares1 = vault_withdraw(assets, caller, caller);
        console.log("withdraw");
        _log(init.user);
        if (!_vaultMayBeEmpty) vm.assume(IERC20(_vault_).totalSupply() > 0);
        vm.prank(caller);
        uint256 shares2 = vault_deposit(assets, caller);
        console.log("deposit");
        _log(init.user);
        uint256 assetsAfter = vault_convertToAssets(IERC4626(_vault_).balanceOf(caller));
        assertApproxLeAbs(assetsAfter, assetsBefore, _delta_);
    }

    function _log(address[4] memory users) private view {
        console.log("ERC4626StrategyVault");
        Logger.log(erc4626StrategyVault, users);
        console.log("ERC4626StrategyVault.vault()");
        Logger.log(erc4626StrategyVault.vault(), [address(erc4626StrategyVault), address(cryticERC4626StrategyVault)]);
    }

    function test_ERC4626StrategyVaultERC4626Std_test_RT_withdraw_mint_01() public {
        Init memory init = Init({
            user: [
                0x00000000000000000000000000000000000045B1,
                0x00000000000000000000000000000000000004C7,
                0x0000000000000000000000000000000000000dD3,
                0x000000000000000000000000000000000000102C
            ],
            share: [uint256(3578229790), uint256(13566), uint256(14027), uint256(767)],
            asset: [uint256(9614), uint256(6709), uint256(1303), uint256(1900)],
            yield: int256(10430)
        });
        test_RT_withdraw_mint(init, 3247934751);
    }

    function test_ERC4626StrategyVaultERC4626Std_test_RT_withdraw_mint_02() public {
        // [FAIL; counterexample: calldata=0x6aaa88bc0000000000000000000000000000000000000000000000000000000000001bfb0000000000000000000000000000000000000000000000000000000000002de300000000000000000000000000000000000000000000000000000000000016010000000000000000000000000000000000000000000000000000000000000378000000000000000000000000000000000000000000001010102b30b63ab290320000000000000000000000000000000000000000000000000000000000001eee000000000000000000000000000000000000000000000000000000000000049e000000000000000000000000000000000000000000000000000000000000146b00000000000000000000000000000000000000000000000000000000000006e900000000000000000000000000000000000000000000000000000000000040f10000000000000000000000000000000000000000000000000000000000001edc0000000000000000000000000000000000000000000000000000000000001b9000000000000000000000000000000000000000000000000000000000000014970000000000000000000000000000000000000000000000000000000000002c5d args=[Init({ user: [0x0000000000000000000000000000000000001Bfb, 0x0000000000000000000000000000000000002dE3, 0x0000000000000000000000000000000000001601, 0x0000000000000000000000000000000000000378], share: [75854176709581508612146 [7.585e22], 7918, 1182, 5227], asset: [1769, 16625 [1.662e4], 7900, 7056], yield: 5271 }), 11357 [1.135e4]]] test_RT_withdraw_mint((address[4],uint256[4],uint256[4],int256),uint256) (runs: 2, μ: 811764, ~: 811764)
        Init memory init = Init({
            user: [
                0x0000000000000000000000000000000000001Bfb,
                0x0000000000000000000000000000000000002dE3,
                0x0000000000000000000000000000000000001601,
                0x0000000000000000000000000000000000000378
            ],
            share: [uint256(75854176709581508612146), uint256(7918), uint256(1182), uint256(5227)],
            asset: [uint256(1769), uint256(16625), uint256(7900), uint256(7056)],
            yield: int256(5271)
        });
        uint256 assets = 11357;

        setUpVault(init);
        console.log("setUpVault");
        _log(init.user);
        address caller = init.user[0];
        uint256 assetsBefore =
            vault_convertToAssets(IERC4626(_vault_).balanceOf(caller)) + IERC20(_underlying_).balanceOf(caller);
        assets = bound(assets, 0, _max_withdraw(caller));
        _approve(_underlying_, caller, _vault_, type(uint256).max);
        vm.prank(caller);
        uint256 shares = vault_withdraw(assets, caller, caller);
        console.log("withdraw");
        _log(init.user);
        if (!_vaultMayBeEmpty) vm.assume(IERC20(_vault_).totalSupply() > 0);
        vm.prank(caller);
        uint256 assets2 = vault_mint(shares, caller);
        console.log("mint");
        _log(init.user);
        uint256 assetsAfter =
            vault_convertToAssets(IERC4626(_vault_).balanceOf(caller)) + IERC20(_underlying_).balanceOf(caller);
        assertApproxLeAbs(assetsAfter, assetsBefore, _delta_);
    }
}
