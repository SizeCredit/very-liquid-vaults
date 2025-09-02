// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseVault} from "@src/utils/BaseVault.sol";

/// @title NonReentrantVault
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice A vault that is non-reentrant
/// @dev Extends BaseVault to make it non-reentrant
abstract contract NonReentrantVault is BaseVault {
  // ERC4626 OVERRIDES
  function deposit(uint256 assets, address receiver) public override(BaseVault) nonReentrant returns (uint256) {
    return super.deposit(assets, receiver);
  }

  function mint(uint256 shares, address receiver) public override(BaseVault) nonReentrant returns (uint256) {
    return super.mint(shares, receiver);
  }

  function withdraw(uint256 assets, address receiver, address owner) public override(BaseVault) nonReentrant returns (uint256) {
    return super.withdraw(assets, receiver, owner);
  }

  function redeem(uint256 shares, address receiver, address owner) public override(BaseVault) nonReentrant returns (uint256) {
    return super.redeem(shares, receiver, owner);
  }
}
