// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SizeVaultScript is Script {
    IERC20Metadata asset;
    address admin;

    function setUp() public {
        asset = IERC20Metadata(vm.envAddress("ASSET"));
        admin = vm.envAddress("ADMIN");
    }

    function run() public {
        vm.startBroadcast();

        deploy(asset, admin);

        vm.stopBroadcast();
    }

    function deploy(IERC20Metadata asset_, address admin_) public returns (SizeVault) {
        return SizeVault(
            address(
                new ERC1967Proxy(
                    address(new SizeVault()),
                    abi.encodeCall(
                        SizeVault.initialize,
                        (
                            asset_,
                            string.concat("Size ", asset_.name(), " Vault"),
                            string.concat("size", asset_.symbol()),
                            admin_
                        )
                    )
                )
            )
        );
    }
}
