// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {SizeMetaVaultScript} from "@script/SizeMetaVault.s.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CashStrategyVaultScript} from "@script/CashStrategyVault.s.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {AaveStrategyVaultScript} from "@script/AaveStrategyVault.s.sol";
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
import {Auth, SIZE_VAULT_ROLE} from "@src/utils/Auth.sol";
import {AuthScript} from "@script/Auth.s.sol";
import {BaseVaultMock} from "@test/mocks/BaseVaultMock.t.sol";
import {BaseVaultMockScript} from "@script/BaseVaultMock.s.sol";
import {CryticSizeMetaVaultMock} from "@test/mocks/CryticSizeMetaVaultMock.t.sol";
import {CryticSizeMetaVaultMockScript} from "@script/CryticSizeMetaVaultMock.s.sol";
import {IBaseVault} from "@src/IBaseVault.sol";
import {WETH9} from "@aave/contracts/dependencies/weth/WETH9.sol";

abstract contract Setup {
    uint256 internal FIRST_DEPOSIT_AMOUNT;
    uint256 internal WETH_DEPOSIT_AMOUNT;

    uint256 private constant INITIAL_STRATEGIES_COUNT = 3;

    SizeMetaVault internal sizeMetaVault;
    CashStrategyVault internal cashStrategyVault;
    CashStrategyVault internal cashStrategyVaultWETH;
    CryticCashStrategyVaultMock internal cryticCashStrategyVault;
    AaveStrategyVault internal aaveStrategyVault;
    CryticAaveStrategyVaultMock internal cryticAaveStrategyVault;
    ERC4626StrategyVault internal erc4626StrategyVault;
    CryticERC4626StrategyVaultMock internal cryticERC4626StrategyVault;
    BaseVaultMock internal baseVault;
    CryticSizeMetaVaultMock internal cryticSizeMetaVault;
    IERC20Metadata internal erc20Asset;
    WETH9 internal weth;
    PoolMock internal pool;
    VaultMock internal erc4626Vault;
    IAToken internal aToken;
    Auth internal auth;

    function deploy(address admin) public {
        erc20Asset = IERC20Metadata(new USDC(admin));
        weth = new WETH9();
        FIRST_DEPOSIT_AMOUNT = 10 * (10 ** erc20Asset.decimals());
        WETH_DEPOSIT_AMOUNT = 0.1e18;
        (
            AuthScript authScript,
            SizeMetaVaultScript sizeMetaVaultScript,
            CashStrategyVaultScript cashStrategyVaultScript,
            CashStrategyVaultScript cashStrategyVaultScriptWETH,
            AaveStrategyVaultScript aaveStrategyVaultScript,
            ERC4626StrategyVaultScript erc4626StrategyVaultScript,
            CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
            CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
            CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
            BaseVaultMockScript baseVaultMockScript,
            CryticSizeMetaVaultMockScript cryticSizeMetaVaultMockScript,
            PoolMockScript poolMockScript,
            VaultMockScript vaultMockScript
        ) = _deployScripts();
        _mintToScripts(
            USDC(address(erc20Asset)),
            admin,
            sizeMetaVaultScript,
            cashStrategyVaultScript,
            cashStrategyVaultScriptWETH,
            aaveStrategyVaultScript,
            erc4626StrategyVaultScript,
            cryticCashStrategyVaultScript,
            cryticAaveStrategyVaultScript,
            cryticERC4626StrategyVaultScript,
            cryticSizeMetaVaultMockScript,
            baseVaultMockScript
        );
        _deployContracts(
            admin,
            authScript,
            sizeMetaVaultScript,
            cashStrategyVaultScript,
            cashStrategyVaultScriptWETH,
            aaveStrategyVaultScript,
            erc4626StrategyVaultScript,
            cryticCashStrategyVaultScript,
            cryticAaveStrategyVaultScript,
            cryticERC4626StrategyVaultScript,
            cryticSizeMetaVaultMockScript,
            baseVaultMockScript,
            poolMockScript,
            vaultMockScript
        );
        vm.prank(admin);
        auth.grantRole(SIZE_VAULT_ROLE, address(sizeMetaVault));
    }

    function _deployScripts()
        internal
        returns (
            AuthScript authScript,
            SizeMetaVaultScript sizeMetaVaultScript,
            CashStrategyVaultScript cashStrategyVaultScript,
            CashStrategyVaultScript cashStrategyVaultScriptWETH,
            AaveStrategyVaultScript aaveStrategyVaultScript,
            ERC4626StrategyVaultScript erc4626StrategyVaultScript,
            CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
            CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
            CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
            BaseVaultMockScript baseVaultMockScript,
            CryticSizeMetaVaultMockScript cryticSizeMetaVaultMockScript,
            PoolMockScript poolMockScript,
            VaultMockScript vaultMockScript
        )
    {
        authScript = new AuthScript();
        sizeMetaVaultScript = new SizeMetaVaultScript();
        cashStrategyVaultScript = new CashStrategyVaultScript();
        cashStrategyVaultScriptWETH = new CashStrategyVaultScript();
        aaveStrategyVaultScript = new AaveStrategyVaultScript();
        erc4626StrategyVaultScript = new ERC4626StrategyVaultScript();
        cryticCashStrategyVaultScript = new CryticCashStrategyVaultMockScript();
        cryticAaveStrategyVaultScript = new CryticAaveStrategyVaultMockScript();
        cryticERC4626StrategyVaultScript = new CryticERC4626StrategyVaultMockScript();
        cryticSizeMetaVaultMockScript = new CryticSizeMetaVaultMockScript();
        baseVaultMockScript = new BaseVaultMockScript();
        poolMockScript = new PoolMockScript();
        vaultMockScript = new VaultMockScript();
    }

    function _mintToScripts(
        USDC usdc,
        address admin,
        SizeMetaVaultScript sizeMetaVaultScript,
        CashStrategyVaultScript cashStrategyVaultScript,
        CashStrategyVaultScript cashStrategyVaultScriptWETH,
        AaveStrategyVaultScript aaveStrategyVaultScript,
        ERC4626StrategyVaultScript erc4626StrategyVaultScript,
        CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
        CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
        CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
        CryticSizeMetaVaultMockScript cryticSizeMetaVaultMockScript,
        BaseVaultMockScript baseVaultMockScript
    ) internal {
        address[7] memory scripts = [
            address(cashStrategyVaultScript),
            address(aaveStrategyVaultScript),
            address(erc4626StrategyVaultScript),
            address(cryticCashStrategyVaultScript),
            address(cryticAaveStrategyVaultScript),
            address(cryticERC4626StrategyVaultScript),
            address(baseVaultMockScript)
        ];
        for (uint256 i = 0; i < scripts.length; i++) {
            vm.prank(admin);
            usdc.mint(scripts[i], FIRST_DEPOSIT_AMOUNT);
        }
        vm.prank(admin);
        usdc.mint(address(sizeMetaVaultScript), INITIAL_STRATEGIES_COUNT * FIRST_DEPOSIT_AMOUNT + 1);
        vm.prank(admin);
        usdc.mint(address(cryticSizeMetaVaultMockScript), INITIAL_STRATEGIES_COUNT * FIRST_DEPOSIT_AMOUNT + 1);

        vm.deal(admin, WETH_DEPOSIT_AMOUNT);
        vm.prank(admin);
        weth.deposit{value: WETH_DEPOSIT_AMOUNT}();
        vm.prank(admin);
        weth.transfer(address(cashStrategyVaultScriptWETH), WETH_DEPOSIT_AMOUNT);
    }

    function _deployContracts(
        address admin,
        AuthScript authScript,
        SizeMetaVaultScript sizeMetaVaultScript,
        CashStrategyVaultScript cashStrategyVaultScript,
        CashStrategyVaultScript cashStrategyVaultScriptWETH,
        AaveStrategyVaultScript aaveStrategyVaultScript,
        ERC4626StrategyVaultScript erc4626StrategyVaultScript,
        CryticCashStrategyVaultMockScript cryticCashStrategyVaultScript,
        CryticAaveStrategyVaultMockScript cryticAaveStrategyVaultScript,
        CryticERC4626StrategyVaultMockScript cryticERC4626StrategyVaultScript,
        CryticSizeMetaVaultMockScript cryticSizeMetaVaultMockScript,
        BaseVaultMockScript baseVaultMockScript,
        PoolMockScript poolMockScript,
        VaultMockScript vaultMockScript
    ) internal {
        auth = authScript.deploy(admin);
        pool = poolMockScript.deploy(admin, erc20Asset);
        erc4626Vault = vaultMockScript.deploy(admin, erc20Asset, "Vault", "VAULT");
        cashStrategyVault = cashStrategyVaultScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT);
        cashStrategyVaultWETH =
            cashStrategyVaultScriptWETH.deploy(auth, IERC20Metadata(address(weth)), WETH_DEPOSIT_AMOUNT);
        aaveStrategyVault = aaveStrategyVaultScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT, pool);
        erc4626StrategyVault = erc4626StrategyVaultScript.deploy(auth, FIRST_DEPOSIT_AMOUNT, erc4626Vault);
        cryticCashStrategyVault = cryticCashStrategyVaultScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT);
        cryticAaveStrategyVault = cryticAaveStrategyVaultScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT, pool);
        cryticERC4626StrategyVault = cryticERC4626StrategyVaultScript.deploy(auth, FIRST_DEPOSIT_AMOUNT, erc4626Vault);
        IBaseVault[] memory strategies = new IBaseVault[](3);
        strategies[0] = cryticCashStrategyVault;
        strategies[1] = cryticAaveStrategyVault;
        strategies[2] = cryticERC4626StrategyVault;
        cryticSizeMetaVault = cryticSizeMetaVaultMockScript.deploy(
            auth, erc20Asset, strategies.length * FIRST_DEPOSIT_AMOUNT + 1, strategies
        );
        baseVault = baseVaultMockScript.deploy(auth, erc20Asset, FIRST_DEPOSIT_AMOUNT);
        strategies = new IBaseVault[](3);
        strategies[0] = cashStrategyVault;
        strategies[1] = aaveStrategyVault;
        strategies[2] = erc4626StrategyVault;
        sizeMetaVault =
            sizeMetaVaultScript.deploy(auth, erc20Asset, strategies.length * FIRST_DEPOSIT_AMOUNT + 1, strategies);
        aToken = IAToken(pool.getReserveData(address(erc20Asset)).aTokenAddress);
    }
}
