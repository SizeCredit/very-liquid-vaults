// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626StrategyVault} from "@src/strategies/ERC4626StrategyVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract ERC4626StrategyVaultScript is Script {
    using SafeERC20 for IERC20Metadata;

    Auth auth;
    IERC20Metadata asset;
    uint256 firstDepositAmount;
    IERC4626 vault;

    function setUp() public {
        asset = IERC20Metadata(vm.envAddress("ASSET"));
        auth = Auth(vm.envAddress("AUTH"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
        vault = IERC4626(vm.envAddress("VAULT"));
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, asset, firstDepositAmount, vault);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, IERC20Metadata asset_, uint256 firstDepositAmount_, IERC4626 vault_)
        public
        returns (ERC4626StrategyVault erc4626StrategyVault)
    {
        string memory name = string.concat("ERC4626 ", asset_.name(), " Strategy");
        string memory symbol = string.concat("erc4626", asset_.symbol());
        address implementation = address(new ERC4626StrategyVault());
        bytes memory initializationData =
            abi.encodeCall(ERC4626StrategyVault.initialize, (auth_, asset_, name, symbol, firstDepositAmount_, vault_));
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        erc4626StrategyVault = ERC4626StrategyVault(Create2.computeAddress(salt, keccak256(creationCode)));
        asset_.forceApprove(address(erc4626StrategyVault), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
