# size-meta-vault [![Coverage Status](https://coveralls.io/repos/github/SizeCredit/size-meta-vault/badge.svg?branch=main)](https://coveralls.io/github/SizeCredit/size-meta-vault?branch=main) [![CI](https://github.com/SizeCredit/size-meta-vault/actions/workflows/ci.yml/badge.svg)](https://github.com/SizeCredit/size-meta-vault/actions/workflows/ci.yml)

A modular, upgradeable vault system built on ERC4626 that enables flexible asset management through multiple investment strategies.

## Overview

Size Meta Vault is a "meta vault" implementation that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management. The design is heavily influenced by [yearn's yVaults v3](https://docs.yearn.fi/developers/v3/overview).

## Security

This project implements ERC4626 property tests from [A16Z](https://github.com/a16z/erc4626-tests), [Trail of Bits' Crytic](https://github.com/crytic/properties), and [Runtime Verification](https://github.com/runtimeverification/ercx-tests). In addition, several security-focused remediations for common vault attacks were introduced:

- OpenZeppelin's implementation with decimals offset ([A Novel Defense Against ERC4626 Inflation Attacks](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks))
- First deposit during deployment with dead shares, pioneered by the [Morpho Optimizer](https://github.com/morpho-org/morpho-optimizers-vaults/blob/a74846774afe4f74a75a0470c2984c7d8ea41f35/scripts/aave-v2/eth-mainnet/Deploy.s.sol#L85-L120)

## Key Features

* **ERC4626 Compliance**: Standard vault interface for seamless DeFi integration
* **Multi-Strategy Architecture**: Support for multiple investment strategies with dynamic allocation
* **Upgradeable Design**: Built with OpenZeppelin's UUPS upgradeable contracts pattern
* **Role-Based Access Control**: Granular permissions for different system operations
* **Strategy Rebalancing**: Manual fund movement between strategies by Strategist
* **Deposit/Withdrawal Priority Logic**: Configurable priority list for liquidity deposit/withdrawals
* **Flexible Strategy Integration**: Easily add or remove ERC4626-compatible strategies
* **Pause Functionality**: Emergency stop mechanisms for enhanced security

## Specifications

### Liquidity Management

* Supports allocation across:
  * Cash (gas-efficient, instant access)
  * Aave (yield-bearing lowest risk venue)
  * Morpho/Euler (yield-bearing righer risk/return venues)
* Liquidity is fungible: all users share average yield
* Default deposit destination is Cash for instant liquidity
* Governance-defined deposit/withdrawal priority

### Rebalancing

* Allocation is manually managed by a Strategist
* Percentage allocations are defined off-chain, e.g., 5% Cash, 50% Aave, 45% Euler
* Strategist uses e.g. `transferAssets` functions to move liquidity between strategies

### Extensibility

* Strategies are ERC4626-compliant vaults or adapters
* Supports future integrations (e.g., staking, async ERC-7540 venues)
* Upgradeable via UUPS proxy pattern
* Role-based access control for safety and flexibility

## Architecture

### Core Components

* **`SizeMetaVault`**: Main vault contract that manages user deposits and strategy allocation
* **`BaseVault`**: Base implementation providing core ERC4626 functionality
* **`BaseStrategyVault`**: Abstract base contract for all investment strategies
* **`Auth`**: Role-based access control system

### Available Strategies

1. **`CashStrategyVault`**: Simple cash-holding strategy (no yield generation)
2. **`AaveStrategyVault`**: Aave lending protocol integration for yield generation
3. **`ERC4626StrategyVault`**: Generic wrapper for other ERC4626-compliant vaults (e.g., Morpho)

## Usage

### Strategy Management

```solidity
// Add a new strategy (requires STRATEGIST_ROLE)
vault.addStrategy(strategyAddress);

// Remove a strategy
vault.removeStrategy(strategyAddress);

// Rebalance between strategies
vault.rebalance(fromStrategy, toStrategy, amount);

// Set multiple strategies at once
address[] memory strategies = [strategy1, strategy2];
vault.setStrategies(strategies);
```

### User Operations

```solidity
// Deposit assets (default to Cash strategy)
vault.deposit(amount, receiver);

// Withdraw assets (follows withdrawal priority list)
vault.withdraw(amount, receiver, owner);

// Check user balance
uint256 shares = vault.balanceOf(user);
uint256 assets = vault.convertToAssets(shares);
```

## Roles and Permissions

* **`DEFAULT_ADMIN_ROLE`**
* **`STRATEGIST_ROLE`**: Rebalance across strategies
* **`PAUSER_ROLE`**: Emergency pause functionality: per vault or whole protocol

## Future Considerations

* **Performance Fees**: Optional fee mechanism
* **Async Withdrawals**: Not supported at launch; can be added later via ERC-7540
* **Venue Flexibility**: Architecture supports delayed withdrawal venues in future
