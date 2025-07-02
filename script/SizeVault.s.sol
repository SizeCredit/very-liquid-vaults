// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract SizeVaultScript is Script {
    using SafeERC20 for IERC20;

    Auth auth;
    IERC20Metadata asset;
    uint256 firstDepositAmount;
    address[] strategies;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        asset = IERC20Metadata(vm.envAddress("ASSET"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
        strategies = vm.envAddress("STRATEGIES", ",");
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, asset, firstDepositAmount, strategies);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, IERC20Metadata asset_, uint256 firstDepositAmount_, address[] memory strategies_)
        public
        returns (SizeVault sizeVault)
    {
        string memory name = string.concat("Size ", asset_.name(), " Vault");
        string memory symbol = string.concat("size", asset_.symbol());
        address implementation = address(new SizeVault());
        bytes memory initializationData =
            abi.encodeCall(SizeVault.initialize, (auth_, asset_, name, symbol, firstDepositAmount_, strategies_));
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        sizeVault = SizeVault(Create2.computeAddress(salt, keccak256(creationCode)));
        IERC20(address(asset_)).forceApprove(address(sizeVault), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
