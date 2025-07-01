# Size Vault

A modular, upgradeable vault system built on ERC4626 that enables flexible asset management through multiple investment strategies.

## Overview

Size Vault is a sophisticated DeFi vault implementation that allows users to deposit assets and have them automatically allocated across multiple investment strategies. The system is built with upgradeability and modularity in mind, featuring role-based access control and comprehensive strategy management.

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

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd size-vault

# Install dependencies
forge install

# Build the project
forge build
```

## Testing

```bash
# Run all tests
forge test

# Run tests with coverage
forge coverage

# Run specific test file
forge test --match-contract SizeVaultTest
```

## Usage

### Basic Deployment

```solidity
// Deploy Auth contract
Auth auth = new Auth();

// Deploy SizeVault
SizeVault vault = new SizeVault();
vault.initialize(
    auth,
    IERC20(assetToken),
    "Size Vault Token",
    "SVT",
    1000 // firstDepositAmount
);

// Deploy and add strategies
CashStrategyVault cashStrategy = new CashStrategyVault();
cashStrategy.initialize(auth, vault, IERC20(assetToken), "Cash Strategy", "CS", 1000);

vault.addStrategy(address(cashStrategy));
```

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

## Security Features

- **Reentrancy Protection**: All external functions protected against reentrancy attacks
- **Pausable Operations**: Emergency stop functionality
- **Access Control**: Role-based permissions for sensitive operations
- **Upgradeable Pattern**: Secure upgrade mechanism with proper initialization

## Development

### Project Structure

```
src/
├── Auth.sol                    # Role-based access control
├── BaseVault.sol              # Base ERC4626 implementation
├── SizeVault.sol              # Main vault contract
└── strategies/
    ├── IStrategy.sol          # Strategy interface
    ├── BaseStrategyVault.sol  # Base strategy implementation
    ├── CashStrategyVault.sol  # Cash holding strategy
    ├── AaveStrategyVault.sol  # Aave integration strategy
    └── ERC4626StrategyVault.sol # Generic ERC4626 wrapper

test/
├── SizeVault.t.sol           # Main vault tests
├── strategies/               # Strategy-specific tests
└── external/                 # External test suites (a16z, Crytic)
```

### Testing Framework

The project includes comprehensive testing using:
- **Foundry**: Primary testing framework
- **a16z ERC4626 Tests**: Standard compliance testing
- **Crytic/Echidna**: Fuzzing and property-based testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Audit Status

This codebase has not been audited. Use at your own risk in production environments.