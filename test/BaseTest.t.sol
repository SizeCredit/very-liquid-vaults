// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {SizeVaultScript} from "@script/SizeVault.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CashStrategyVaultScript} from "@script/CashStrategyVault.s.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {CashStrategyVaultScript as BaseStrategyVaultMockScript} from "@script/BaseStrategyVaultMock.s.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {CryticCashStrategyVaultMock} from "@test/mocks/CryticCashStrategyVaultMock.t.sol";
import {CryticCashStrategyVaultMockScript} from "@script/CryticCashStrategyVaultMock.s.sol";
import {Setup, Contracts} from "@test/Setup.t.sol";

contract BaseTest is Test, Setup {
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    SizeVault internal sizeVault;
    CashStrategyVault internal cashStrategyVault;
    CryticCashStrategyVaultMock internal cryticCashStrategyVault;
    BaseStrategyVaultMock internal baseStrategyVault;
    IERC20Metadata internal asset;

    address internal alice = address(0x10000);
    address internal bob = address(0x20000);
    address internal charlie = address(0x30000);
    address internal admin = address(0x40000);

    function setUp() public virtual {
        Contracts memory contracts = setup(admin);
        sizeVault = contracts.sizeVault;
        cashStrategyVault = contracts.cashStrategyVault;
        cryticCashStrategyVault = contracts.cryticCashStrategyVault;
        baseStrategyVault = contracts.baseStrategyVault;
        asset = contracts.asset;
    }

    function _mint(IERC20Metadata _asset, address _to, uint256 _amount) internal {
        deal(address(_asset), _to, _amount);
    }

    function _approve(address _user, IERC20Metadata _asset, address _spender, uint256 _amount) internal {
        vm.prank(_user);
        _asset.approve(_spender, _amount);
    }

    function assertEq(uint256 _a, uint256 _b, uint256 _c) internal pure {
        assertEq(_a, _b);
        assertEq(_a, _c);
    }
}
