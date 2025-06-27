// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";

contract AaveStrategyVaultScript is Script {
    SizeVault sizeVault;
    IPool pool;

    function setUp() public {
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
        pool = IPool(vm.envAddress("POOL"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(sizeVault, pool);

        vm.stopBroadcast();
    }

    function deploy(SizeVault sizeVault_, IPool pool_) public returns (AaveStrategyVault) {
        return AaveStrategyVault(
            address(
                new ERC1967Proxy(
                    address(new AaveStrategyVault()),
                    abi.encodeCall(
                        AaveStrategyVault.initialize,
                        (
                            sizeVault_,
                            string.concat("Size Aave ", IERC20Metadata(address(sizeVault_.asset())).name(), " Strategy"),
                            string.concat("sizeAave", IERC20Metadata(address(sizeVault_.asset())).symbol()),
                            pool_
                        )
                    )
                )
            )
        );
    }
}
