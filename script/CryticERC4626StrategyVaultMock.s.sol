// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CryticERC4626StrategyVaultMock} from "@test/mocks/CryticERC4626StrategyVaultMock.t.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {VaultMock} from "@test/mocks/VaultMock.t.sol";

contract CryticERC4626StrategyVaultMockScript is Script {
    SizeVault sizeVault;
    VaultMock vault;

    function setUp() public {
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
        vault = VaultMock(vm.envAddress("VAULT"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(sizeVault, vault);

        vm.stopBroadcast();
    }

    function deploy(SizeVault sizeVault_, VaultMock vault_) public returns (CryticERC4626StrategyVaultMock) {
        return CryticERC4626StrategyVaultMock(
            address(
                new ERC1967Proxy(
                    address(new CryticERC4626StrategyVaultMock()),
                    abi.encodeCall(
                        ERC4626StrategyVault.initialize,
                        (
                            sizeVault_,
                            string.concat(
                                "Size Crytic ERC4626 ",
                                IERC20Metadata(address(sizeVault_.asset())).name(),
                                " Strategy Mock"
                            ),
                            string.concat(
                                "sizeCryticERC4626", IERC20Metadata(address(sizeVault_.asset())).symbol(), "MOCK"
                            ),
                            vault_
                        )
                    )
                )
            )
        );
    }
}
