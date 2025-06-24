// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {BaseStrategy} from "@src/strategies/BaseStrategy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {STRATEGIST_ROLE} from "@src/SizeVault.sol";

contract ERC4626Strategy is BaseStrategy {
    using SafeERC20 for IERC20;

    function description() external view override returns (string memory) {
        return string.concat("ERC4626 ", IERC20Metadata(asset()).symbol(), " Strategy");
    }

    function pullAssets(address to, uint256 amount)
        public
        override
        whenNotPaused
        whenSizeVaultNotPaused
        onlySizeVault
    {
        // TODO withdraw funds from vault
        IERC20(asset()).safeTransfer(to, amount);
    }
}
