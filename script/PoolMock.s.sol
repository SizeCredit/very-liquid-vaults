// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PoolMock} from "@test/mocks/PoolMock.t.sol";

contract PoolMockScript is Script {
    address owner;

    function setUp() public {
        owner = vm.envAddress("OWNER");
    }

    function run() public {
        vm.startBroadcast();

        deploy(owner);

        vm.stopBroadcast();
    }

    function deploy(address owner_) public returns (PoolMock) {
        return new PoolMock(owner_);
    }
}
