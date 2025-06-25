// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CashStrategyVault} from "@src/strategies/CashStrategyVault.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";

contract CashStrategyVaultScript is Script {
    SizeVault sizeVault;

    function setUp() public {
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(sizeVault);

        vm.stopBroadcast();
    }

    function deploy(SizeVault sizeVault_) public returns (CashStrategyVault) {
        return CashStrategyVault(
            address(
                new ERC1967Proxy(
                    address(new CashStrategyVault()),
                    abi.encodeCall(
                        BaseStrategyVault.initialize,
                        (
                            sizeVault_,
                            string.concat("Size Cash ", IERC20Metadata(address(sizeVault_.asset())).name(), " Strategy"),
                            string.concat("sizeCash", IERC20Metadata(address(sizeVault_.asset())).symbol())
                        )
                    )
                )
            )
        );
    }
}
