// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AaveStrategyVault} from "@src/strategies/AaveStrategyVault.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract AaveStrategyVaultScript is Script {
    using SafeERC20 for IERC20;

    Auth auth;
    SizeVault sizeVault;
    uint256 firstDepositAmount;
    IPool pool;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
        pool = IPool(vm.envAddress("POOL"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, sizeVault, firstDepositAmount, pool);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, SizeVault sizeVault_, uint256 firstDepositAmount_, IPool pool_)
        public
        returns (AaveStrategyVault aaveStrategyVault)
    {
        string memory name =
            string.concat("Size Aave ", IERC20Metadata(address(sizeVault_.asset())).name(), " Strategy");
        string memory symbol = string.concat("sizeAave", IERC20Metadata(address(sizeVault_.asset())).symbol());
        address implementation = address(new AaveStrategyVault());
        bytes memory initializationData = abi.encodeCall(
            AaveStrategyVault.initialize,
            (auth_, sizeVault_, IERC20(sizeVault_.asset()), name, symbol, firstDepositAmount_, pool_)
        );
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        aaveStrategyVault = AaveStrategyVault(Create2.computeAddress(salt, keccak256(creationCode)));
        IERC20(address(sizeVault_.asset())).forceApprove(address(aaveStrategyVault), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
