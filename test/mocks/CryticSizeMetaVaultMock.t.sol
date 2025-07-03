// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {CryticIERC4626Internal} from "@crytic/properties/contracts/ERC4626/util/IERC4626Internal.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {hevm as vm} from "@crytic/properties/contracts/util/Hevm.sol";
import {IERC20MintBurn} from "@test/mocks/IERC20MintBurn.t.sol";

contract CryticSizeMetaVaultMock is SizeMetaVault, CryticIERC4626Internal {
    function recognizeProfit(uint256 profit) external override {
        address owner = Ownable(asset()).owner();
        address cashStrategy = getStrategy(0);
        vm.prank(owner);
        IERC20MintBurn(asset()).mint(address(cashStrategy), profit);
    }

    function recognizeLoss(uint256 loss) external override {
        address owner = Ownable(asset()).owner();
        address cashStrategy = getStrategy(0);
        vm.prank(owner);
        IERC20MintBurn(asset()).burn(address(cashStrategy), loss);
    }
}
