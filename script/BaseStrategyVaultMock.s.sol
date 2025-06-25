// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.sol";

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

    function deploy(SizeVault sizeVault_) public returns (BaseStrategyVaultMock) {
        return BaseStrategyVaultMock(
            address(
                new ERC1967Proxy(
                    address(new BaseStrategyVaultMock()),
                    abi.encodeCall(
                        BaseStrategyVault.initialize,
                        (
                            sizeVault_,
                            string.concat(
                                "Size Base ", IERC20Metadata(address(sizeVault_.asset())).name(), " Strategy Mock"
                            ),
                            string.concat("sizeBase", IERC20Metadata(address(sizeVault_.asset())).symbol(), "MOCK")
                        )
                    )
                )
            )
        );
    }
}
