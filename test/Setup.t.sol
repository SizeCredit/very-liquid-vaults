// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
import {ERC4626StrategyVaultScript} from "@script/ERC4626StrategyVault.s.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {VaultMock} from "@test/mocks/VaultMock.t.sol";
import {VaultMockScript} from "@script/VaultMock.s.sol";
import {CryticERC4626StrategyVaultMock} from "@test/mocks/CryticERC4626StrategyVaultMock.t.sol";
import {CryticERC4626StrategyVaultMockScript} from "@script/CryticERC4626StrategyVaultMock.s.sol";
import {IAToken} from "@aave/contracts/interfaces/IAToken.sol";
import {Auth} from "@src/Auth.sol";
import {AuthScript} from "@script/Auth.s.sol";

abstract contract Setup {
    uint256 internal FIRST_DEPOSIT_AMOUNT;

    SizeVault internal sizeVault;
    CashStrategyVault internal cashStrategyVault;
    CryticCashStrategyVaultMock internal cryticCashStrategyVault;
    AaveStrategyVault internal aaveStrategyVault;
    CryticAaveStrategyVaultMock internal cryticAaveStrategyVault;
    BaseStrategyVaultMock internal baseStrategyVault;
    ERC4626StrategyVault internal erc4626StrategyVault;
    CryticERC4626StrategyVaultMock internal cryticERC4626StrategyVault;
    IERC20Metadata internal erc20Asset;
    PoolMock internal pool;
    VaultMock internal erc4626Vault;
    IAToken internal aToken;
    Auth internal auth;

    function deploy(address admin) public {
        USDC usdc = _deployUSDC(admin);
        FIRST_DEPOSIT_AMOUNT = 10 * (10 ** erc20Asset.decimals());
        (
            AuthScript authScript,
            SizeVaultScript sizeVaultScript,
            CashStrategyVaultScript cashStrategyVaultScript,
            AaveStrategyVaultScript aaveStrategyVaultScript,
            ERC4626StrategyVaultScript erc4626StrategyVaultScript,
            CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
            CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
            CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
            BaseStrategyVaultMockScript baseStrategyVaultScript,
            PoolMockScript poolMockScript,
            VaultMockScript vaultMockScript
        ) = _deployScripts();
        _mintToScripts(
            usdc,
            admin,
            sizeVaultScript,
            cashStrategyVaultScript,
            aaveStrategyVaultScript,
            erc4626StrategyVaultScript,
            cryticCashStrategyVaultScript,
            cryticAaveStrategyVaultScript,
            cryticERC4626StrategyVaultScript,
            baseStrategyVaultScript
        );
        _deployContracts(
            admin,
            authScript,
            sizeVaultScript,
            cashStrategyVaultScript,
            aaveStrategyVaultScript,
            erc4626StrategyVaultScript,
            cryticCashStrategyVaultScript,
            cryticAaveStrategyVaultScript,
            cryticERC4626StrategyVaultScript,
            baseStrategyVaultScript,
            poolMockScript,
            vaultMockScript
        );
    }

    function _deployUSDC(address admin) internal returns (USDC usdc) {
        usdc = new USDC(admin);
        erc20Asset = IERC20Metadata(address(usdc));
    }

    function _deployScripts()
        internal
        returns (
            AuthScript authScript,
            SizeVaultScript sizeVaultScript,
            CashStrategyVaultScript cashStrategyVaultScript,
            AaveStrategyVaultScript aaveStrategyVaultScript,
            ERC4626StrategyVaultScript erc4626StrategyVaultScript,
            CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
            CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
            CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
            BaseStrategyVaultMockScript baseStrategyVaultScript,
            PoolMockScript poolMockScript,
            VaultMockScript vaultMockScript
        )
    {
        authScript = new AuthScript();
        sizeVaultScript = new SizeVaultScript();
        cashStrategyVaultScript = new CashStrategyVaultScript();
        aaveStrategyVaultScript = new AaveStrategyVaultScript();
        erc4626StrategyVaultScript = new ERC4626StrategyVaultScript();
        cryticCashStrategyVaultScript = new CryticCashStrategyVaultMockScript();
        cryticAaveStrategyVaultScript = new CryticAaveStrategyVaultMockScript();
        cryticERC4626StrategyVaultScript = new CryticERC4626StrategyVaultMockScript();
        baseStrategyVaultScript = new BaseStrategyVaultMockScript();
        poolMockScript = new PoolMockScript();
        vaultMockScript = new VaultMockScript();
    }

    function _mintToScripts(
        USDC usdc,
        address admin,
        SizeVaultScript sizeVaultScript,
        CashStrategyVaultScript cashStrategyVaultScript,
        AaveStrategyVaultScript aaveStrategyVaultScript,
        ERC4626StrategyVaultScript erc4626StrategyVaultScript,
        CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
        CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
        CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
        BaseStrategyVaultMockScript baseStrategyVaultScript
    ) internal {
        address[8] memory scripts = [
            address(sizeVaultScript),
            address(cashStrategyVaultScript),
            address(aaveStrategyVaultScript),
            address(erc4626StrategyVaultScript),
            address(cryticCashStrategyVaultScript),
            address(cryticAaveStrategyVaultScript),
            address(cryticERC4626StrategyVaultScript),
            address(baseStrategyVaultScript)
        ];
        for (uint256 i = 0; i < scripts.length; i++) {
            vm.prank(admin);
            usdc.mint(scripts[i], FIRST_DEPOSIT_AMOUNT);
        }
    }

    function _deployContracts(
        address admin,
        AuthScript authScript,
        SizeVaultScript sizeVaultScript,
        CashStrategyVaultScript cashStrategyVaultScript,
        AaveStrategyVaultScript aaveStrategyVaultScript,
        ERC4626StrategyVaultScript erc4626StrategyVaultScript,
        CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
        CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
        CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
        BaseStrategyVaultMockScript baseStrategyVaultScript,
        PoolMockScript poolMockScript,
        VaultMockScript vaultMockScript
    ) internal {
        auth = authScript.deploy(admin);
        pool = poolMockScript.deploy(admin, erc20Asset);
        erc4626Vault = vaultMockScript.deploy(admin, erc20Asset, "Vault", "VAULT");
        sizeVault = sizeVaultScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT);
        cashStrategyVault = cashStrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT);
        aaveStrategyVault = aaveStrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT, pool);
        erc4626StrategyVault = erc4626StrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT, erc4626Vault);
        cryticCashStrategyVault = cryticCashStrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT);
        cryticAaveStrategyVault = cryticAaveStrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT, pool);
        cryticERC4626StrategyVault =
            cryticERC4626StrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT, erc4626Vault);
        baseStrategyVault = baseStrategyVaultScript.deploy(auth, sizeVault, FIRST_DEPOSIT_AMOUNT);
        aToken = IAToken(pool.getReserveData(address(erc20Asset)).aTokenAddress);
    }
}
