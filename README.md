# Size Meta Vault

A modular, upgradeable vault system built on ERC4626 that enables flexible asset management through multiple investment strategies.

## Overview

Size Meta Vault is a "meta vault" implementation that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management.

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
  * Aave (yield-bearing)
  * Morpho/Euler (yield-bearing)
* Liquidity is fungible: all users share average yield
* Default deposit destination is **Cash** for instant liquidity
* Governance-defined **deposit/withdrawal priority**

### Rebalancing

* Allocation is manually managed by a Strategist (off-chain logic)
* Target allocations (example): 5% Cash, 50% Aave, 45% Euler
* Drift tolerated; no onchain automation
* Strategist uses e.g. `depositToX()` and `withdrawFromX()` functions to move liquidity

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

* **Performance Fees**: Optional fee mechanism (initially not implemented)
* **Async Withdrawals**: Not supported at launch; can be added later via ERC-7540
* **Venue Flexibility**: Architecture supports delayed withdrawal venues in future

## License

MIT
