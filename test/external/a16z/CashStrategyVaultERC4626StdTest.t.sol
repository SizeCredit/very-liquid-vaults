// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Test} from "@a16z/erc4626-tests/ERC4626.test.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CashStrategyVaultERC4626StdTest is ERC4626Test, BaseTest {
    function setUp() public override(ERC4626Test, BaseTest) {
        super.setUp();

        vm.prank(admin);
        Ownable(address(asset)).transferOwnership(address(this));

        _underlying_ = address(asset);
        _vault_ = address(cashStrategyVault);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }
}
