// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Test, IMockERC20} from "@a16z/erc4626-tests/ERC4626.test.sol";
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

    function test_ERC4626StrategyVaultERC4626Std_test_RT_withdraw_deposit_01() public {
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
        _log();
        address caller = init.user[0];
        assets = bound(assets, 0, _max_withdraw(caller));
        _approve(_underlying_, caller, _vault_, type(uint256).max);
        vm.prank(caller);
        uint256 shares1 = vault_withdraw(assets, caller, caller);
        console.log("withdraw");
        _log();
        if (!_vaultMayBeEmpty) vm.assume(IERC20(_vault_).totalSupply() > 0);
        vm.prank(caller);
        uint256 shares2 = vault_deposit(assets, caller);
        console.log("deposit");
        _log();
        assertApproxLeAbs(shares2, shares1, _delta_);
    }

    function _log() private view {
        console.log("ERC4626StrategyVault");
        Logger.log(
            erc4626StrategyVault,
            [
                0x00000000000000000000000000000000000030b3,
                0x0000000000000000000000000000000000002367,
                0x0000000000000000000000000000000000001B08,
                0x0000000000000000000000000000000000002D7E
            ]
        );
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

    function test_RT_withdraw_deposit(Init memory init, uint256 assets) public override {
        // ignore
    }

    function test_RT_deposit_withdraw(Init memory init, uint256 shares) public override {
        // ignore
    }

    function test_RT_redeem_mint(Init memory init, uint256 shares) public override {
        // ignore
    }

    function test_RT_withdraw_mint(Init memory init, uint256 assets) public override {
        // ignore
    }
}
