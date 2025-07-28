// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";

/// @title CashStrategyVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A strategy that only holds cash assets without investing in external protocols
/// @dev Extends BaseStrategy for cash management within the Size Meta Vault system
contract CashStrategyVault is BaseVault {}
