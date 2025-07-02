// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626Test} from "@rv/ercx/src/ERC4626/Light/ERC4626Test.sol";
import {Setup} from "@test/Setup.t.sol";

contract AaveStrategyVaultRVTest is ERC4626Test, Setup {
    function setUp() public {
        deploy(address(this));
        ERC4626Test.init(address(aaveStrategyVault));
    }

    // NOTE: these tests fail because AToken.burn/AToken.mint disallows 0 amounts
    // ignore testDepositZeroAmountIsPossible
    // ignore testMintZeroAmountIsPossible
    // ignore testRedeemZeroAmountIsPossible
    // ignore testWithdrawZeroAmountIsPossible
    // NOTE: these tests fail because the implementation of ERC4626Test uses `asset()` to issue approvals
    // ignore testDepositSupportsEIP20ApproveTransferFromAssets
    // ignore testMintSupportsEIP20ApproveTransferFromAssets
    // NOTE: these tests fail because AToken.mint cannot go as near to type(uint256).max because of WadRayMath
    // ignore testDealIntendedSharesToDummyUsers
}
