// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SizeVault} from "@src/SizeVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CryticSizeVaultMock} from "@test/mocks/CryticSizeVaultMock.t.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";

contract CryticSizeVaultMockScript is Script {
    using SafeERC20 for IERC20Metadata;

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
        returns (CryticSizeVaultMock cryticSizeVaultMock)
    {
        string memory name = string.concat("Crytic Size ", asset_.name(), " Vault");
        string memory symbol = string.concat("cryticSize", asset_.symbol(), "MOCK");
        address implementation = address(new CryticSizeVaultMock());
        bytes memory initializationData =
            abi.encodeCall(SizeVault.initialize, (auth_, asset_, name, symbol, firstDepositAmount_, strategies_));
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        cryticSizeVaultMock = CryticSizeVaultMock(Create2.computeAddress(salt, keccak256(creationCode)));
        asset_.forceApprove(address(cryticSizeVaultMock), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
