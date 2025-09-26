# very-liquid-vaults [![Coverage Status](https://coveralls.io/repos/github/SizeCredit/very-liquid-vaults/badge.svg?branch=main)](https://coveralls.io/github/SizeCredit/very-liquid-vaults?branch=main) [![CI](https://github.com/SizeCredit/very-liquid-vaults/actions/workflows/ci.yml/badge.svg)](https://github.com/SizeCredit/very-liquid-vaults/actions/workflows/ci.yml)

A modular, upgradeable ERC4626 vault system that enables flexible asset management through multiple investment strategies.

## Overview

Very Liquid Vault is a "meta" vault that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management. The design is influenced by [yearn's yVaults v3](https://docs.yearn.fi/developers/v3/overview).

## Security

- ERC4626 property tests from [A16Z](https://github.com/a16z/erc4626-tests), [Trail of Bits' Crytic](https://github.com/crytic/properties), and [Runtime Verification](https://github.com/runtimeverification/ercx-tests)
- OpenZeppelin's implementation with decimals offset ([A Novel Defense Against ERC4626 Inflation Attacks](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks))
- First deposit during deployment with dead shares, pioneered by the [Morpho Optimizer](https://github.com/morpho-org/morpho-optimizers-vaults/blob/a74846774afe4f74a75a0470c2984c7d8ea41f35/scripts/aave-v2/eth-mainnet/Deploy.s.sol#L85-L120)
- Timelock for sensitive operations using OpenZeppelin's [TimelockController](https://docs.openzeppelin.com/defender/guide/timelock-roles)
- Invariant tests for [a list of system properties](test/property/PropertiesSpecifications.t.sol)

## Audits

| Date | Version | Auditor | Report |
|------|---------|----------|---------|
| 2025-09-11 | v0.1.0 | Open Zeppelin | [Report](./audits/2025-09-11-OpenZeppelin.pdf) |
| 2025-07-26 | v0.0.1 | Obsidian Audits | [Report](./audits/2025-07-26-Obsidian-Audits.pdf) |

## Deployments

#### Ethereum

| Contract | Address |
|----------|---------|
| TimelockController (DEFAULT_ADMIN_ROLE) | [0x220d1165798AC86BD70D987aDfc9E5FF8A317363](https://etherscan.io/address/0x220d1165798AC86BD70D987aDfc9E5FF8A317363) |
| TimelockController (VAULT_MANAGER_ROLE) | [0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e](https://etherscan.io/address/0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e) |
| Auth | [0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84](https://etherscan.io/address/0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84) |
| CashStrategyVault | [0x096A1e4176ca516Bced19B15903EaB4654f7ee7A](https://etherscan.io/address/0x096A1e4176ca516Bced19B15903EaB4654f7ee7A) |
| AaveStrategyVault | [0x30c37256cD4DbaC733D815ae520F94A9aDAff579](https://etherscan.io/address/0x30c37256cD4DbaC733D815ae520F94A9aDAff579) |
| ERC4626StrategyVault (Morpho/Steakhouse) | [0x0860b5C685a7985789251f54524c49d71D56d10D](https://etherscan.io/address/0x0860b5C685a7985789251f54524c49d71D56d10D) |
| ERC4626StrategyVault (Euler/Prime Gauntlet) | [0x2ae61A7463667503Ab530b17B387A448B0471bcC](https://etherscan.io/address/0x2ae61A7463667503Ab530b17B387A448B0471bcC) |
| ERC4626StrategyVault (Euler/Yield Gauntlet) | [0xd72d29287503ccDa5bd9131baA8D96df436dcdf0](https://etherscan.io/address/0xd72d29287503ccDa5bd9131baA8D96df436dcdf0) |
| ERC4626StrategyVault (Morpho/Smokehouse) | [0x23de7fC5C9dc55B076558E6Be0cfA7755Bb5F38b](https://etherscan.io/address/0x23de7fC5C9dc55B076558E6Be0cfA7755Bb5F38b) |
| ERC4626StrategyVault (Morpho/MEV Capital) | [0xc266c2544B768D94b627d66060E2662533a1Dee3](https://etherscan.io/address/0xc266c2544B768D94b627d66060E2662533a1Dee3) |
| VeryLiquidVault (Core) | [0x3AdF08AFe804691cA6d76742367cc50A24a1F4A1](https://etherscan.io/address/0x3AdF08AFe804691cA6d76742367cc50A24a1F4A1) |
| VeryLiquidVault (Frontier) | [0x13dDa6fD149a4Da0f2012F16e70925586ee603b8](https://etherscan.io/address/0x13dDa6fD149a4Da0f2012F16e70925586ee603b8) |

#### Base

| Contract | Address |
|----------|---------|
| TimelockController (DEFAULT_ADMIN_ROLE) | [0x220d1165798AC86BD70D987aDfc9E5FF8A317363](https://basescan.org/address/0x220d1165798AC86BD70D987aDfc9E5FF8A317363) |
| TimelockController (VAULT_MANAGER_ROLE) | [0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e](https://basescan.org/address/0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e) |
| Auth | [0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84](https://basescan.org/address/0xB5294A791c37DFdc2228FACEd7dCE8EFCEb14B84) |
| CashStrategyVault | [0xe822Cb00dd72a2278F623b82D0234b15241bcFD9](https://basescan.org/address/0xe822Cb00dd72a2278F623b82D0234b15241bcFD9) |
| AaveStrategyVault | [0x63954A96A4e77A96cf78C3A4959c45123cdA5de1](https://basescan.org/address/0x63954A96A4e77A96cf78C3A4959c45123cdA5de1) |
| ERC4626StrategyVault (Morpho/Spark) | [0x930D8350ff644114d9fc29D820228ACd0cC719ed](https://basescan.org/address/0x930D8350ff644114d9fc29D820228ACd0cC719ed) |
| ERC4626StrategyVault (Morpho/Gauntlet Prime) | [0x40AEb7c4c392f90b37E0ff0caC005FA7804653Ec](https://basescan.org/address/0x40AEb7c4c392f90b37E0ff0caC005FA7804653Ec) |
| ERC4626StrategyVault (Morpho/Moonwell Flagship) | [0xddED8eaB321803a3c2e836cAADD54339f4CDD5d1](https://basescan.org/address/0xddED8eaB321803a3c2e836cAADD54339f4CDD5d1) |
| ERC4626StrategyVault (Morpho/Steakhouse) | [0x5a33c8517f4DDD3939a87fEAaaAaF570a542D2aD](https://basescan.org/address/0x5a33c8517f4DDD3939a87fEAaaAaF570a542D2aD) |
| VeryLiquidVault (Core) | [0xf4D43A8570Dad86595fc079c633927aa936264F4](https://basescan.org/address/0xf4D43A8570Dad86595fc079c633927aa936264F4) |

## Key Features

* **ERC-4626 Compliance**: Standard vault interface for seamless DeFi integration
* **Multi-Strategy Architecture**: Support for multiple investment strategies with dynamic allocation
* **Upgradeable Design**: Built with OpenZeppelin's UUPS upgradeable contracts pattern
* **ERC-7201**: Namespaced Storage Layout to facilitate inheritance and upgradeability
* **Role-Based Access Control**: Granular permissions for different system operations
* **Strategy Rebalancing**: Manual fund movement between strategies by Strategist
* **Deposit/Withdrawal Priority Logic**: Configurable priority list for liquidity deposit/withdrawals
* **Flexible Strategy Integration**: Easily add or remove ERC4626-compatible strategies
* **Pause Functionality**: Emergency stop mechanisms for enhanced security
* **Total Asset Caps**: Maximum asset limits for each strategy and very liquid
* **Performance Fees**: Performance fee is minted as shares if the overall vault tokens have an appreciated price beyond the previous high water mark

## Specifications

### Liquidity Management

* Supports allocation across:
  * Cash
  * Aave
  * Morpho/Euler
* Liquidity is fungible: all users share average yield
* Default deposit destination is Cash for instant liquidity (as defined by the strategist)
* Strategist-defined deposit/withdrawal priority

### Rebalancing

* Allocation is manually managed by a Strategist
* Percentage allocations are defined off-chain, e.g., 10% Cash, 30% Aave, 30% Euler, 30% Morpho
* Strategist uses e.g. `rebalance` to move liquidity between strategies

## Architecture

### Core Components

* **`VeryLiquidVault`**: Main vault contract that manages user deposits and strategy allocation
* **`Auth`**: Centralized role-based access control system with global pause functionality

### Available Strategies

1. **`CashStrategyVault`**: Simple cash-holding strategy (no yield generation)
2. **`AaveStrategyVault`**: Aave lending protocol integration for yield generation
3. **`ERC4626StrategyVault`**: Generic wrapper for other ERC4626 vaults (e.g., Morpho). Only ERC-4626 vaults passing the [integration checklist](https://github.com/aviggiano/security/blob/v0.1.0/audit-checklists/ERC-4626-integration.md) will be considered.

## Roles and Permissions

```md
| Role                | Timelock | Actions                                                                   |
|---------------------|----------|---------------------------------------------------------------------------|
| DEFAULT_ADMIN_ROLE  | 7d       | upgrade, grantRole, revokeRole, setPerformanceFeePercent, setFeeRecipient |
| VAULT_MANAGER_ROLE  | 1d       | unpause, addStrategy, setTotalAssetsCap, setRebalanceMaxSlippagePercent   |
| STRATEGIST_ROLE     | 0        | rebalance, reorderStrategies                                              |
| GUARDIAN_ROLE       | 0        | cancel timelock proposals, pause, removeStrategy                          |
```

## Known Limitations

1. When `removeStrategy` is performed, the `VeryLiquidVault` attempts to withdraw all assets from the exiting strategy and re-deposit them into another strategy. If the withdrawal or deposit fails, the whole operation reverts.
2. The performance fee can stop being applied during a significant downturn event, which would cause the price per share to never surpass the high-water mark.
3. Assets directly sent to the vaults may be lost, with the exception of the `CashStrategyVault`, which accepts them as donations.
4. The vaults are not compatible with fee-on-transfer assets.
5. The `ERC4626StrategyVault` cannot be used by vaults that take fees in assets on deposits or withdrawals. All integrated vaults must be strictly ERC-4626 compliant.
6. Read-only reentrancy is not fully mitigated because of how contracts are inherited from OpenZeppelin's `openzeppelin-contracts-upgradeable` library. Practically all ERC20 and ERC4626 view functions cannot be guarded with a `nonReentrantView` modifier, since they are used internally in state-changing functions, which themselves are `nonReentrant`. If we applied `nonReentrantView` to public view functions that are used by nonpayable functions, these would revert.
7. `SizeMetaVault`'s `max{Deposit,Withdraw,Mint,Redeem}` functions may experience precision loss when aggregating the maximum values from underlying strategies.
8. `ERC4626StrategyVault`'s `max{Redeem,Mint}` functions may experience precision loss when converting between the integrated `vault`'s shares, assets, and strategy shares. In particular, this means a user's `balanceOf` may not always be fully `redeem`able, so users should always consult the `max` limits, as specified by ERC-4626.
9. The `reorderStrategies` function has quadtratic complexity due to duplicate detection logic, which is acceptable for the current `MAX_STRATEGIES` cap.  
10. The system assumes that integrated strategies are honest and non-malicious. A malicious or gas-griefing strategy could revert or consume excessive gas in `totalAssets` or other operations.  
11. Onchain price-per-share calculations of integrated vaults (e.g., `ERC4626StrategyVault.vault()` used in many markets) may increase gas costs linearly with the number of underlying markets. This can make `rebalance`, `totalAssets`, and other operations expensive.

### Deployment

#### Governance

```bash
export ADMIN_MULTISIG=XXX
export VAULT_MANAGER_MULTISIG=XXX
export GUARDIANS=XXX
export STRATEGISTS=XXX
forge script script/TimelockControllerEnumerables.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
export TIMELOCK_DEFAULT_ADMIN_ROLE=XXX
export TIMELOCK_VAULT_MANAGER_ROLE=XXX
export ADMIN=$DEPLOYER_ADDRESS
forge script script/Auth.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
forge script script/ConfigureAuthRoles.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
```

#### Vaults

```bash
export AUTH=XXX
forge script script/CashStrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
forge script script/AaveStrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
forge script script/ERC4626StrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
export IDENTIFIER=XXX
export STRATEGIES=XXX
forge script script/VeryLiquidVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
```
