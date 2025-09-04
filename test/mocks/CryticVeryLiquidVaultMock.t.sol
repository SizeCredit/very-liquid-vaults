// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CryticIERC4626Internal} from "@crytic/properties/contracts/ERC4626/util/IERC4626Internal.sol";

import {hevm as vm} from "@crytic/properties/contracts/util/Hevm.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VeryLiquidVault} from "@src/VeryLiquidVault.sol";

import {IERC20MintBurn} from "@test/mocks/IERC20MintBurn.t.sol";

contract CryticVeryLiquidVaultMock is VeryLiquidVault, CryticIERC4626Internal {
    function recognizeProfit(uint256 profit) external override {
        address owner = Ownable(asset()).owner();
        address cashStrategy = address(strategies(0));
        vm.prank(owner);
        IERC20MintBurn(asset()).mint(address(cashStrategy), profit);
    }

    function recognizeLoss(uint256 loss) external override {
        address owner = Ownable(asset()).owner();
        address cashStrategy = address(strategies(0));
        vm.prank(owner);
        IERC20MintBurn(asset()).burn(address(cashStrategy), loss);
    }
}
