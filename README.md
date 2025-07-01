# Size Vault

A modular, upgradeable vault system built on ERC4626 that enables flexible asset management through multiple investment strategies.

## Overview

Size Vault is a "meta vault" implementation that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management.

## Key Features

- **ERC4626 Compliance**: Standard vault interface for seamless DeFi integration
- **Multi-Strategy Architecture**: Support for multiple investment strategies with dynamic allocation
- **Upgradeable Design**: Built with OpenZeppelin's upgradeable contracts pattern
- **Role-Based Access Control**: Granular permissions for different system operations
- **Strategy Rebalancing**: Flexible asset movement between strategies
- **Pause Functionality**: Emergency stop mechanisms for enhanced security

## Architecture

### Core Components

- **`SizeVault`**: Main vault contract that manages user deposits and strategy allocation
- **`BaseVault`**: Base implementation providing core ERC4626 functionality
- **`BaseStrategyVault`**: Abstract base contract for all investment strategies
- **`Auth`**: Role-based access control system

### Available Strategies

1. **`CashStrategyVault`**: Simple cash-holding strategy (no yield generation)
2. **`AaveStrategyVault`**: Aave lending protocol integration for yield generation
3. **`ERC4626StrategyVault`**: Generic wrapper for other ERC4626-compliant vaults

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
// Deposit assets
vault.deposit(amount, receiver);

// Withdraw assets
vault.withdraw(amount, receiver, owner);

// Check user balance
uint256 shares = vault.balanceOf(user);
uint256 assets = vault.convertToAssets(shares);
```

## Roles and Permissions

- **`DEFAULT_ADMIN_ROLE`**: Full system administration
- **`STRATEGIST_ROLE`**: Strategy management and rebalancing
- **`PAUSER_ROLE`**: Emergency pause functionality