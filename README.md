# size-meta-vault [![Coverage Status](https://coveralls.io/repos/github/SizeCredit/size-meta-vault/badge.svg?branch=main)](https://coveralls.io/github/SizeCredit/size-meta-vault?branch=main) [![CI](https://github.com/SizeCredit/size-meta-vault/actions/workflows/ci.yml/badge.svg)](https://github.com/SizeCredit/size-meta-vault/actions/workflows/ci.yml)

A modular, upgradeable ERC4626 vault system that enables flexible asset management through multiple investment strategies.

## Overview

Size Meta Vault is a "meta vault" implementation that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management. The design is influenced by [yearn's yVaults v3](https://docs.yearn.fi/developers/v3/overview).

## Security

This project implements ERC4626 property tests from [A16Z](https://github.com/a16z/erc4626-tests), [Trail of Bits' Crytic](https://github.com/crytic/properties), and [Runtime Verification](https://github.com/runtimeverification/ercx-tests). In addition, several security-focused remediations for common vault attacks were introduced:

- OpenZeppelin's implementation with decimals offset ([A Novel Defense Against ERC4626 Inflation Attacks](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks))
- First deposit during deployment with dead shares, pioneered by the [Morpho Optimizer](https://github.com/morpho-org/morpho-optimizers-vaults/blob/a74846774afe4f74a75a0470c2984c7d8ea41f35/scripts/aave-v2/eth-mainnet/Deploy.s.sol#L85-L120)
- Timelock for sensitive operations

## Audits

This project has not undergone any security reviews yet.

## Deployments

Target deployments:

- Ethereum mainnet
- Base mainnet

Target integrations:

- Aave v3 (USDC)
- Morpho vaults (USDC)
- Euler vaults (USDC)

## Key Features

* **ERC4626 Compliance**: Standard vault interface for seamless DeFi integration
* **Multi-Strategy Architecture**: Support for multiple investment strategies with dynamic allocation
* **Upgradeable Design**: Built with OpenZeppelin's UUPS upgradeable contracts pattern
* **Role-Based Access Control**: Granular permissions for different system operations
* **Strategy Rebalancing**: Manual fund movement between strategies by Strategist
* **Deposit/Withdrawal Priority Logic**: Configurable priority list for liquidity deposit/withdrawals
* **Flexible Strategy Integration**: Easily add or remove ERC4626-compatible strategies
* **Pause Functionality**: Emergency stop mechanisms for enhanced security
* **Total Asset Caps**: Maximum asset limits for each strategy and meta vault
* **Performance Fees**: Performance fee is minted as shares if the overall vault tokens have an appreciated price beyond the previous high water mark

## Specifications

### Liquidity Management

* Supports allocation across:
  * Cash (gas-efficient, instant access)
  * Aave (yield-bearing lowest risk venue)
  * Morpho/Euler (yield-bearing righer risk/return venues)
* Liquidity is fungible: all users share average yield
* Default deposit destination is Cash for instant liquidity (as defined by the strategist)
* Strategist-defined deposit/withdrawal priority

### Rebalancing

* Allocation is manually managed by a Strategist
* Percentage allocations are defined off-chain, e.g., 5% Cash, 50% Aave, 45% Euler
* Strategist uses e.g. `rebalance` to move liquidity between strategies

## Architecture

### Core Components

* **`SizeMetaVault`**: Main vault contract that manages user deposits and strategy allocation
* **`Auth`**: Centralized role-based access control system

### Available Strategies

1. **`CashStrategyVault`**: Simple cash-holding strategy (no yield generation)
2. **`AaveStrategyVault`**: Aave lending protocol integration for yield generation
3. **`ERC4626StrategyVault`**: Generic wrapper for other ERC4626 vaults (e.g., Morpho). Only ERC-4626 vaults passing the [integration checklist](https://github.com/aviggiano/security/blob/v0.1.0/audit-checklists/ERC-4626-integration.md) will be considered. If a vault has fees-on-withdrawal in assets, making it not strictly ERC-4626 compliant, the `ERC4626StrategyVault` will also not be strictly ERC-4626 compliant.

## Roles and Permissions

* **`DEFAULT_ADMIN_ROLE`**: Admin (governance multisig)
* **`STRATEGIST_ROLE`**: Rebalance across strategies, configure strategies through a timelock
* **`PAUSER_ROLE`**: Emergency pause functionality: per vault or whole protocol

### Deployment

```bash
forge script script/Auth.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
export AUTH=XXX
forge script script/CashStrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
forge script script/AaveStrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
forge script script/ERC4626StrategyVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
export STRATEGIES=XXX
forge script script/SizeMetaVault.s.sol --rpc-url $RPC_URL --gas-limit 30000000 --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT --verify -vvvvv [--slow]
export SIZE_META_VAULT=XXX
cast send $AUTH "grantRole(bytes32,address)" $(cast k SIZE_VAULT_ROLE) $SIZE_META_VAULT --rpc-url $RPC_URL --account $DEPLOYER_ACCOUNT -vvvvv
```
