// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SizeVault} from "@src/SizeVault.sol";
import {SizeVaultScript} from "@script/SizeVault.s.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CashStrategyVaultScript} from "@script/CashStrategyVault.s.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {CashStrategyVaultScript as BaseStrategyVaultMockScript} from "@script/BaseStrategyVaultMock.s.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {CryticCashStrategyVaultMock} from "@test/mocks/CryticCashStrategyVaultMock.t.sol";
import {CryticCashStrategyVaultMockScript} from "@script/CryticCashStrategyVaultMock.s.sol";
import {USDC} from "@test/mocks/USDC.t.sol";

struct Contracts {
    SizeVault sizeVault;
    CashStrategyVault cashStrategyVault;
    CryticCashStrategyVaultMock cryticCashStrategyVault;
    BaseStrategyVaultMock baseStrategyVault;
    IERC20Metadata asset;
}

abstract contract Setup {
    function deploy(address admin) public returns (Contracts memory) {
        Contracts memory contracts;
        contracts.asset = IERC20Metadata(address(new USDC(admin)));
        contracts.sizeVault = (new SizeVaultScript()).deploy(contracts.asset, admin);
        contracts.cashStrategyVault = (new CashStrategyVaultScript()).deploy(contracts.sizeVault);
        contracts.cryticCashStrategyVault = (new CryticCashStrategyVaultMockScript()).deploy(contracts.sizeVault);
        contracts.baseStrategyVault = (new BaseStrategyVaultMockScript()).deploy(contracts.sizeVault);
        return contracts;
    }
}
