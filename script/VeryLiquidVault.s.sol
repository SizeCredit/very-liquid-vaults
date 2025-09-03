// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseScript} from "@script/BaseScript.s.sol";
import {Auth} from "@src/Auth.sol";
import {VeryLiquidVault} from "@src/VeryLiquidVault.sol";

import {IVault} from "@src/IVault.sol";
import {console} from "forge-std/console.sol";

contract VeryLiquidVaultScript is BaseScript {
  using SafeERC20 for IERC20;

  string identifier;
  Auth auth;
  IERC20Metadata asset;
  address fundingAccount = address(this);
  uint256 veryLiquidVaultFirstDepositAmount;
  IVault[] strategies;

  function setUp() public override {
    super.setUp();

    identifier = vm.envString("IDENTIFIER");
    auth = Auth(vm.envAddress("AUTH"));
    asset = IERC20Metadata(vm.envAddress("ASSET"));
    fundingAccount = msg.sender;
    veryLiquidVaultFirstDepositAmount = vm.envUint("VERY_LIQUID_VAULT_FIRST_DEPOSIT_AMOUNT");
    address[] memory strategies_ = vm.envAddress("STRATEGIES", ",");
    strategies = new IVault[](strategies_.length);
    for (uint256 i = 0; i < strategies_.length; i++) {
      strategies[i] = IVault(strategies_[i]);
    }
  }

  function run() public {
    vm.startBroadcast();

    console.log("VeryLiquidVault", address(deploy(identifier, auth, asset, veryLiquidVaultFirstDepositAmount, strategies)));

    vm.stopBroadcast();
  }

  function deploy(string memory identifier_, Auth auth_, IERC20Metadata asset_, uint256 veryLiquidVaultFirstDepositAmount_, IVault[] memory strategies_)
    public
    returns (VeryLiquidVault veryLiquidVault)
  {
    string memory name = string.concat("Very Liquid ", identifier_, " ", asset_.name(), " Vault");
    string memory symbol = string.concat("vlv", identifier_, asset_.symbol());
    address implementation = address(new VeryLiquidVault());
    bytes memory initializationData = abi.encodeCall(VeryLiquidVault.initialize, (auth_, asset_, name, symbol, fundingAccount, veryLiquidVaultFirstDepositAmount_, strategies_));
    bytes memory creationCode = abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData));
    bytes32 salt = keccak256(initializationData);
    veryLiquidVault = VeryLiquidVault(create2Deployer.computeAddress(salt, keccak256(creationCode)));
    IERC20(address(asset_)).forceApprove(address(veryLiquidVault), veryLiquidVaultFirstDepositAmount_);
    create2Deployer.deploy(0, salt, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializationData)));
  }
}
