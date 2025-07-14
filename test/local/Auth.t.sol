// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Auth} from "@src/Auth.sol";
import {BaseTest} from "@test/BaseTest.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AuthTest is BaseTest {
    function test_Auth_upgrade() public {
        Auth newAuth = new Auth();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        auth.upgradeToAndCall(address(newAuth), abi.encodeCall(Auth.initialize, (alice)));

        vm.prank(admin);
        auth.upgradeToAndCall(address(newAuth), "");
    }
}
