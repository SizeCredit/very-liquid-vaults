// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";

abstract contract Addresses {
    enum Contract {
        GovernanceMultisig,
        TimelockController_DEFAULT_ADMIN_ROLE,
        TimelockController_VAULT_MANAGER_ROLE,
        Auth,
        CashStrategyVault,
        AaveStrategyVault,
        ERC4626StrategyVault_Morpho_Steakhouse,
        ERC4626StrategyVault_Euler_Prime_Gauntlet,
        ERC4626StrategyVault_Euler_Yield_Gauntlet,
        ERC4626StrategyVault_Morpho_Smokehouse,
        ERC4626StrategyVault_Morpho_MEV_Capital,
        VeryLiquidVault_Core,
        VeryLiquidVault_Frontier,
        ERC4626StrategyVault_Morpho_Spark,
        ERC4626StrategyVault_Morpho_Gauntlet_Prime,
        ERC4626StrategyVault_Morpho_Moonwell_Flagship
    }

    mapping(uint256 chainId => mapping(Contract c => address a)) public addresses;

    constructor() {
        // Ethereum
        addresses[1][Contract.GovernanceMultisig] = 0xa9c62d9E0F2208456E50B208aE2547F36Bc3452d;
        addresses[1][Contract.TimelockController_DEFAULT_ADMIN_ROLE] = 0x220d1165798AC86BD70D987aDfc9E5FF8A317363;
        addresses[1][Contract.TimelockController_VAULT_MANAGER_ROLE] = 0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e;
        addresses[1][Contract.Auth] = 0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84;
        addresses[1][Contract.CashStrategyVault] = 0x096A1e4176ca516Bced19B15903EaB4654f7ee7A;
        addresses[1][Contract.AaveStrategyVault] = 0x30c37256cD4DbaC733D815ae520F94A9aDAff579;
        addresses[1][Contract.ERC4626StrategyVault_Morpho_Steakhouse] = 0x0860b5C685a7985789251f54524c49d71D56d10D;
        addresses[1][Contract.ERC4626StrategyVault_Euler_Prime_Gauntlet] = 0x2ae61A7463667503Ab530b17B387A448B0471bcC;
        addresses[1][Contract.ERC4626StrategyVault_Euler_Yield_Gauntlet] = 0xd72d29287503ccDa5bd9131baA8D96df436dcdf0;
        addresses[1][Contract.ERC4626StrategyVault_Morpho_Smokehouse] = 0x23de7fC5C9dc55B076558E6Be0cfA7755Bb5F38b;
        addresses[1][Contract.ERC4626StrategyVault_Morpho_MEV_Capital] = 0xc266c2544B768D94b627d66060E2662533a1Dee3;
        addresses[1][Contract.VeryLiquidVault_Core] = 0x3AdF08AFe804691cA6d76742367cc50A24a1F4A1;
        addresses[1][Contract.VeryLiquidVault_Frontier] = 0x13dDa6fD149a4Da0f2012F16e70925586ee603b8;

        // Base
        addresses[8453][Contract.GovernanceMultisig] = 0xa9c62d9E0F2208456E50B208aE2547F36Bc3452d;
        addresses[8453][Contract.TimelockController_DEFAULT_ADMIN_ROLE] = 0x220d1165798AC86BD70D987aDfc9E5FF8A317363;
        addresses[8453][Contract.TimelockController_VAULT_MANAGER_ROLE] = 0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e;
        addresses[8453][Contract.Auth] = 0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84;
        addresses[8453][Contract.CashStrategyVault] = 0xe822Cb00dd72a2278F623b82D0234b15241bcFD9;
        addresses[8453][Contract.AaveStrategyVault] = 0x63954A96A4e77A96cf78C3A4959c45123cdA5de1;
        addresses[8453][Contract.ERC4626StrategyVault_Morpho_Spark] = 0x930D8350ff644114d9fc29D820228ACd0cC719ed;
        addresses[8453][Contract.ERC4626StrategyVault_Morpho_Gauntlet_Prime] =
            0x40AEb7c4c392f90b37E0ff0caC005FA7804653Ec;
        addresses[8453][Contract.ERC4626StrategyVault_Morpho_Moonwell_Flagship] =
            0xddED8eaB321803a3c2e836cAADD54339f4CDD5d1;
        addresses[8453][Contract.ERC4626StrategyVault_Morpho_Steakhouse] = 0x5a33c8517f4DDD3939a87fEAaaAaF570a542D2aD;
        addresses[8453][Contract.VeryLiquidVault_Core] = 0xf4D43A8570Dad86595fc079c633927aa936264F4;
    }
}
