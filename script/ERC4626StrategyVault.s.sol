// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract ERC4626StrategyVaultScript is Script {
    SizeVault sizeVault;
    IERC4626 vault;

    function setUp() public {
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
        vault = IERC4626(vm.envAddress("VAULT"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(sizeVault, vault);

        vm.stopBroadcast();
    }

    function deploy(SizeVault sizeVault_, IERC4626 vault_) public returns (ERC4626StrategyVault) {
        return ERC4626StrategyVault(
            address(
                new ERC1967Proxy(
                    address(new ERC4626StrategyVault()),
                    abi.encodeCall(
                        ERC4626StrategyVault.initialize,
                        (
                            sizeVault_,
                            string.concat("Size ", IERC20Metadata(address(vault_.asset())).name(), " Strategy"),
                            string.concat("size", IERC20Metadata(address(vault_.asset())).symbol()),
                            vault_
                        )
                    )
                )
            )
        );
    }
}
