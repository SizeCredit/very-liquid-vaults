// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {AaveStrategyVaultForkTest} from "@test/fork/strategies/AaveStrategyVaultFork.t.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseScript} from "@script/BaseScript.s.sol";
import {IBaseVault} from "@src/utils/IBaseVault.sol";

contract SizeMetaVaultForkTest is AaveStrategyVaultForkTest {
    using SafeERC20 for IERC20Metadata;

    function setUp() public virtual override {
        super.setUp();

        _mint(asset, address(this), FIRST_DEPOSIT_AMOUNT);

        IBaseVault[] memory initialStrategies = new IBaseVault[](1);
        initialStrategies[0] = IBaseVault(address(aaveStrategyVault));

        address implementation = address(new SizeMetaVault());
        bytes memory initializationData = abi.encodeCall(
            SizeMetaVault.initialize,
            (
                auth,
                IERC20Metadata(address(asset)),
                string.concat("Size ", asset.name(), " Meta Vault"),
                string.concat("size", asset.symbol()),
                address(this),
                FIRST_DEPOSIT_AMOUNT,
                initialStrategies
            )
        );
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        sizeMetaVault = SizeMetaVault(create2Deployer.computeAddress(salt, keccak256(creationCode)));
        asset.forceApprove(address(sizeMetaVault), FIRST_DEPOSIT_AMOUNT);
        create2Deployer.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }

    function testFork_SizeMetaVault_deposit_withdraw_with_interest() public {
        uint256 amount = 10 * 10 ** asset.decimals();

        _mint(asset, alice, amount);
        _approve(alice, asset, address(sizeMetaVault), amount);

        vm.startPrank(alice);

        sizeMetaVault.deposit(amount, alice);

        vm.warp(block.timestamp + 1 weeks);

        uint256 redeemedAssets = sizeMetaVault.redeem(sizeMetaVault.balanceOf(alice), alice, alice);

        assertGt(redeemedAssets, amount);
    }
}
