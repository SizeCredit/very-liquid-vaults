// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BaseStrategyVault} from "@src/strategies/BaseStrategyVault.sol";
import {BaseStrategyVaultMock} from "@test/mocks/BaseStrategyVaultMock.t.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract BaseStrategyVaultMockScript is Script {
    using SafeERC20 for IERC20;

    Auth auth;
    SizeVault sizeVault;
    uint256 firstDepositAmount;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        sizeVault = SizeVault(vm.envAddress("SIZE_VAULT"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, sizeVault, firstDepositAmount);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, SizeVault sizeVault_, uint256 firstDepositAmount_)
        public
        returns (BaseStrategyVaultMock baseStrategyVaultMock)
    {
        string memory name =
            string.concat("Size Base ", IERC20Metadata(address(sizeVault_.asset())).name(), " Strategy Mock");
        string memory symbol = string.concat("sizeBase", IERC20Metadata(address(sizeVault_.asset())).symbol(), "MOCK");
        address implementation = address(new BaseStrategyVaultMock());
        bytes memory initializationData = abi.encodeCall(
            BaseStrategyVault.initialize,
            (auth_, sizeVault_, IERC20(sizeVault_.asset()), name, symbol, firstDepositAmount_)
        );
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        baseStrategyVaultMock = BaseStrategyVaultMock(Create2.computeAddress(salt, keccak256(creationCode)));
        IERC20(address(sizeVault_.asset())).forceApprove(address(baseStrategyVaultMock), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
