// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseVault} from "@src/BaseVault.sol";
import {SizeMetaVaultHelper} from "@test/property/crytic/NewPropertyContracts/SizeMetaVaultHelper.t.sol";
import {IStrategy} from "@src/strategies/IStrategy.sol";

contract SizeMetaVaultPropes is SizeMetaVaultHelper {
    function test_SizeMetaVault_rebalance_propperty_testing(
        uint256 depositAmount,
        uint256 rebalanceAmount,
        uint256 indexFrom,
        uint256 indexTo
    ) public {
        indexFrom = _between(indexFrom, 0, 2);
        indexTo = _between(indexTo, 0, 2);
        while (indexFrom == indexTo) {
            uint256 counter = 0;
            indexTo = _between(indexFrom + counter, 0, 2);
            counter++;
        }

        (
            address strategyFromAddress,
            address strategyToAddress
        ) = _setTwoStrategiesInOrder(indexFrom, indexTo);

        assertEq(sizeMetaVault.strategiesCount(), 2);

        IStrategy strategyFrom = IStrategy(strategyFromAddress);
        IStrategy strategyTo = IStrategy(strategyToAddress);

        depositAmount = _between(depositAmount, 0, type(uint32).max);

        _mint(erc20Asset, alice, depositAmount);
        _approve(alice, erc20Asset, address(sizeMetaVault), depositAmount);

        hevm.prank(alice);
        sizeMetaVault.deposit(depositAmount, alice);

        uint256 assetStrategyFromBefore = strategyFrom.totalAssets();
        uint256 assetStrategyToBefore = strategyTo.totalAssets();

        rebalanceAmount = _between(
            rebalanceAmount,
            0,
            strategyFrom.totalAssets() -
                BaseVault(address(strategyFrom)).deadAssets()
        );

        hevm.prank(strategist);
        sizeMetaVault.rebalance(strategyFrom, strategyTo, rebalanceAmount);
        assertEq(
            strategyFrom.totalAssets(),
            assetStrategyFromBefore - rebalanceAmount
        );
        assertEq(
            strategyTo.totalAssets(),
            assetStrategyToBefore + rebalanceAmount
        );
    }
}
