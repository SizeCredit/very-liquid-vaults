// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "@test/BaseTest.t.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Auth} from "@src/Auth.sol";

contract ForkTest is BaseTest {
    address public constant AAVE_POOL_BASE_MAINNET = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address public constant AAVE_POOL_CONFIGURATOR_BASE_MAINNET = 0x5731a04B1E775f0fdd454Bf70f3335886e9A96be;
    address public constant AAVE_POOL_ADMIN_BASE_MAINNET = 0x9390B1735def18560c509E2d0bc090E9d6BA257a;
    address public constant USDC_BASE_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function setUp() public virtual override {
        vm.createSelectFork("base");

        erc20Asset = IERC20Metadata(USDC_BASE_MAINNET);
        auth = Auth(address(new ERC1967Proxy(address(new Auth()), abi.encodeCall(Auth.initialize, (admin)))));
    }
}
