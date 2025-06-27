// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SizeVault} from "@src/SizeVault.sol";
import {SizeVaultScript} from "@script/SizeVault.s.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CashStrategyVaultScript} from "@script/CashStrategyVault.s.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {BaseStrategyVaultMockScript} from "@script/BaseStrategyVaultMock.s.sol";
import {AaveStrategyVaultScript} from "@script/AaveStrategyVault.s.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {CryticCashStrategyVaultMock} from "@test/mocks/CryticCashStrategyVaultMock.t.sol";
import {CryticCashStrategyVaultMockScript} from "@script/CryticCashStrategyVaultMock.s.sol";
import {CryticAaveStrategyVaultMock} from "@test/mocks/CryticAaveStrategyVaultMock.t.sol";
import {CryticAaveStrategyVaultMockScript} from "@script/CryticAaveStrategyVaultMock.s.sol";
import {USDC} from "@test/mocks/USDC.t.sol";
import {PoolMock} from "@test/mocks/PoolMock.t.sol";
import {PoolMockScript} from "@script/PoolMock.s.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {hevm as vm} from "@crytic/properties/contracts/util/Hevm.sol";

struct Contracts {
    SizeVault sizeVault;
    CashStrategyVault cashStrategyVault;
    AaveStrategyVault aaveStrategyVault;
    CryticCashStrategyVaultMock cryticCashStrategyVault;
    CryticAaveStrategyVaultMock cryticAaveStrategyVault;
    BaseStrategyVaultMock baseStrategyVault;
    IERC20Metadata asset;
    PoolMock pool;
}

abstract contract Setup {
    function deploy(address admin) public returns (Contracts memory) {
        Contracts memory contracts;
        contracts.asset = IERC20Metadata(address(new USDC(admin)));
        contracts.sizeVault = (new SizeVaultScript()).deploy(contracts.asset, admin);
        contracts.cashStrategyVault = (new CashStrategyVaultScript()).deploy(contracts.sizeVault);
        contracts.aaveStrategyVault = (new AaveStrategyVaultScript()).deploy(contracts.sizeVault);
        contracts.cryticCashStrategyVault = (new CryticCashStrategyVaultMockScript()).deploy(contracts.sizeVault);
        contracts.cryticAaveStrategyVault = (new CryticAaveStrategyVaultMockScript()).deploy(contracts.sizeVault);
        contracts.baseStrategyVault = (new BaseStrategyVaultMockScript()).deploy(contracts.sizeVault);
        contracts.pool = (new PoolMockScript()).deploy(admin);

        vm.prank(admin);
        contracts.pool.setLiquidityIndex(address(contracts.asset), WadRayMath.RAY);

        vm.prank(admin);
        contracts.aaveStrategyVault.setPool(contracts.pool);

        return contracts;
    }
}
