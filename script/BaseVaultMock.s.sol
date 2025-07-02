// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseVault} from "@src/BaseVault.sol";
import {BaseVaultMock} from "@test/mocks/BaseVaultMock.t.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auth} from "@src/Auth.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BaseVaultMockScript is Script {
    using SafeERC20 for IERC20Metadata;

    Auth auth;
    IERC20Metadata asset;
    uint256 firstDepositAmount;

    function setUp() public {
        auth = Auth(vm.envAddress("AUTH"));
        asset = IERC20Metadata(vm.envAddress("ASSET"));
        firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
    }

    function run() public {
        vm.startBroadcast();

        deploy(auth, asset, firstDepositAmount);

        vm.stopBroadcast();
    }

    function deploy(Auth auth_, IERC20Metadata asset_, uint256 firstDepositAmount_)
        public
        returns (BaseVaultMock baseVaultMock)
    {
        string memory name = string.concat("Base ", asset_.name(), " Mock");
        string memory symbol = string.concat("base", asset_.symbol(), "MOCK");
        address implementation = address(new BaseVaultMock());
        bytes memory initializationData =
            abi.encodeCall(BaseVault.initialize, (auth_, asset_, name, symbol, firstDepositAmount_));
        bytes memory creationCode =
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
        bytes32 salt = keccak256(initializationData);
        baseVaultMock = BaseVaultMock(Create2.computeAddress(salt, keccak256(creationCode)));
        asset_.forceApprove(address(baseVaultMock), firstDepositAmount_);
        Create2.deploy(
            0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData))
        );
    }
}
