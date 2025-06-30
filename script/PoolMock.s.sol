// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PoolMock} from "@test/mocks/PoolMock.t.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";

contract PoolMockScript is Script {
    address owner;
    IERC20Metadata asset;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        asset = IERC20Metadata(vm.envAddress("ASSET"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(owner, asset);

        vm.stopBroadcast();
    }

    function deploy(address owner_, IERC20Metadata asset_) public returns (PoolMock pool) {
        pool = new PoolMock(owner_);
        vm.prank(owner_);
        pool.setLiquidityIndex(address(asset_), WadRayMath.RAY);
        return pool;
    }
}
