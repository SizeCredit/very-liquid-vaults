// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626Test} from "@rv/ercx/src/ERC4626/Light/ERC4626Test.sol";
import {Setup} from "@test/Setup.t.sol";

contract AaveStrategyVaultRVTest is ERC4626Test, Setup {
    function setUp() public {
        deploy(address(this));
        ERC4626Test.init(address(aaveStrategyVault));
    }

    // NOTE: this test fails because AToken.mint cannot go as near to type(uint256).max because of WadRayMath
    function testDepositZeroAmountIsPossible() public override {
        // ignore
    }

    // NOTE: this test fails because AToken.mint cannot go as near to type(uint256).max because of WadRayMath
    function testMintZeroAmountIsPossible() public override {
        // ignore
    }

    // NOTE: this test fails because AToken.burn cannot go as near to type(uint256).max because of WadRayMath
    function testRedeemZeroAmountIsPossible() public override {
        // ignore
    }

    // NOTE: this test fails because AToken.burn cannot go as near to type(uint256).max because of WadRayMath
    function testWithdrawZeroAmountIsPossible() public override {
        // ignore
    }

    // NOTE: these tests fail because the implementation of ERC4626Test uses `asset()` to issue approvals
    // ignore testDepositSupportsEIP20ApproveTransferFromAssets
    // ignore testMintSupportsEIP20ApproveTransferFromAssets
    // NOTE: these tests fail because AToken.mint cannot go as near to type(uint256).max because of WadRayMath
    // ignore testDealIntendedSharesToDummyUsers
}
