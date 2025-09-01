// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseScript} from "@script/BaseScript.s.sol";
import {Auth} from "@src/Auth.sol";
import {BaseVault} from "@src/utils/BaseVault.sol";
import {BaseVaultMock} from "@test/mocks/BaseVaultMock.t.sol";
import {Script, console} from "forge-std/Script.sol";

contract BaseVaultMockScript is BaseScript {
  using SafeERC20 for IERC20Metadata;

  Auth auth;
  IERC20Metadata asset;
  address fundingAccount = address(this);
  uint256 firstDepositAmount;

  function setUp() public override {
    super.setUp();

    auth = Auth(vm.envAddress("AUTH"));
    asset = IERC20Metadata(vm.envAddress("ASSET"));
    fundingAccount = msg.sender;
    firstDepositAmount = vm.envUint("FIRST_DEPOSIT_AMOUNT");
  }

  function run() public {
    vm.startBroadcast();

    console.log("BaseVaultMock", address(deploy(auth, asset, firstDepositAmount)));

    vm.stopBroadcast();
  }

  function deploy(Auth auth_, IERC20Metadata asset_, uint256 firstDepositAmount_) public returns (BaseVaultMock baseVaultMock) {
    string memory name = string.concat("Very Liquid Base ", asset_.name(), " Mock Vault");
    string memory symbol = string.concat("vlv", "Base", asset_.symbol(), "Mock");
    address implementation = address(new BaseVaultMock());
    bytes memory initializationData = abi.encodeCall(BaseVault.initialize, (auth_, asset_, name, symbol, fundingAccount, firstDepositAmount_));
    bytes memory creationCode = abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
    bytes32 salt = keccak256(initializationData);
    baseVaultMock = BaseVaultMock(create2Deployer.computeAddress(salt, keccak256(creationCode)));
    asset_.forceApprove(address(baseVaultMock), firstDepositAmount_);
    create2Deployer.deploy(0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData)));
  }
}
