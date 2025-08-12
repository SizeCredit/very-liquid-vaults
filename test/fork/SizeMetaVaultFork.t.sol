// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {ForkTest} from "@test/fork/ForkTest.t.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseScript} from "@script/BaseScript.s.sol";
import {IVault} from "@src/utils/IVault.sol";

contract SizeMetaVaultForkTest is ForkTest {
    using SafeERC20 for IERC20Metadata;

    function testFork_SizeMetaVault_deposit_withdraw_with_interest() public {
        uint256 amount = 10 * 10 ** erc20Asset.decimals();

        _mint(erc20Asset, alice, amount);
        _approve(alice, erc20Asset, address(sizeMetaVault), amount);

        vm.startPrank(alice);

        sizeMetaVault.deposit(amount, alice);

        vm.warp(block.timestamp + 1 weeks);

        uint256 maxRedeem = sizeMetaVault.maxRedeem(alice);
        uint256 redeemedAssets = sizeMetaVault.redeem(maxRedeem, alice, alice);

        assertGt(redeemedAssets, 0);
    }
}
