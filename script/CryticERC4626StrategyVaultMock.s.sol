// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeMetaVault} from "@src/SizeMetaVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CryticERC4626StrategyVaultMock} from "@test/mocks/CryticERC4626StrategyVaultMock.t.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {VaultMock} from "@test/mocks/VaultMock.t.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract CryticERC4626StrategyVaultMockScript is Script {
    using SafeERC20 for IERC20Metadata;

    Auth auth;
    IERC20Metadata asset;
    uint256 firstDepositAmount;
    VaultMock vault;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        asset = IERC20Metadata(vm.envAddress("ASSET"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
        vault = VaultMock(vm.envAddress("VAULT"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, asset, firstDepositAmount, vault);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, IERC20Metadata asset_, uint256 firstDepositAmount_, VaultMock vault_)
        public
        returns (CryticERC4626StrategyVaultMock cryticERC4626StrategyVaultMock)
    {
        string memory name = string.concat("Crytic ERC4626 ", asset_.name(), " Strategy Mock");
        string memory symbol = string.concat("cryticERC4626", asset_.symbol(), "MOCK");
        address implementation = address(new CryticERC4626StrategyVaultMock());
        bytes memory initializationData =
            abi.encodeCall(ERC4626StrategyVault.initialize, (auth_, asset_, name, symbol, firstDepositAmount_, vault_));
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        cryticERC4626StrategyVaultMock =
            CryticERC4626StrategyVaultMock(Create2.computeAddress(salt, keccak256(creationCode)));
        asset_.forceApprove(address(cryticERC4626StrategyVaultMock), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
