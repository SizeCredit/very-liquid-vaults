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
| TBD | v0.1.0 | TBD | TBD |
| 2025-07-26 | v0.0.1 | Obsidian Audits | [Report](./audits/2025-07-26-Obsidian-Audits.pdf) |

## Deployments

Target deployments:

| Network | Contract | Address |
|---------|----------|---------|
| Ethereum | TimelockController (DEFAULT_ADMIN_ROLE) | |
| Ethereum | TimelockController (VAULT_MANAGER_ROLE) | |
| Base | TimelockController (DEFAULT_ADMIN_ROLE) | [0x220d1165798AC86BD70D987aDfc9E5FF8A317363](https://basescan.org/address/0x220d1165798AC86BD70D987aDfc9E5FF8A317363) |
| Base | TimelockController (VAULT_MANAGER_ROLE) | [0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e](https://basescan.org/address/0xcDB5eC52Cc326711461f93909d767E31fCfF7A1e) |
| Base | Auth | - |
| Base | CashStrategyVault | - |

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
| Role                | Timelock | Actions                                                     |
|---------------------|----------|-------------------------------------------------------------|
| DEFAULT_ADMIN_ROLE  | 7d       | upgrade, grantRole, revokeRole, setPerformanceFeePercent    |
| VAULT_MANAGER_ROLE  | 1d       | unpause, addStrategy, setTotalAssetsCap                     |
| STRATEGIST_ROLE     | 0        | rebalance, reorderStrategies                                |
| GUARDIAN_ROLE       | 0        | cancel any pending proposals, pause, removeStrategy         |
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
