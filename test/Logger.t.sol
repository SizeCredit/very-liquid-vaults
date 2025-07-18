// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {console} from "forge-std/Test.sol";

// TODO: generalize
library Logger {
    function spaces(uint256 n) public pure returns (string memory ans) {
        for (uint256 i = 0; i < n; i++) {
            ans = string.concat(ans, " ");
        }
    }

    function padStart(uint256 value, uint256 n) public pure returns (string memory ans) {
        ans = Strings.toString(value);
        uint256 length = bytes(ans).length;
        uint256 pad = n > length ? n - length : 0;
        for (uint256 i = 0; i < pad; i++) {
            ans = string.concat(" ", ans);
        }
    }

    function log(IERC4626 vault, address[] memory users) public view {
        string memory line = "";
        line = string.concat(
            line, spaces(42 - 4 - 2), "user", "\t", spaces(10 - 6), "shares", "\t", spaces(10 - 6), "assets", "\n"
        );
        for (uint256 i = 0; i < users.length; i++) {
            line = string.concat(
                line,
                Strings.toHexString(users[i]),
                "\t",
                padStart(vault.balanceOf(users[i]), 10),
                "\t",
                padStart(vault.convertToAssets(vault.balanceOf(users[i])), 10),
                "\n"
            );
        }
        line = string.concat(
            line,
            spaces(42 - 5),
            "total",
            "\t",
            padStart(vault.totalSupply(), 10),
            "\t",
            padStart(vault.totalAssets(), 10),
            "\n"
        );
        console.log(line);
    }

    function log(IERC4626 vault, address[2] memory users) public view {
        address[] memory _users = new address[](2);
        for (uint256 i = 0; i < users.length; i++) {
            _users[i] = users[i];
        }
        log(vault, _users);
    }

    function log(IERC4626 vault, address[1] memory users) public view {
        address[] memory _users = new address[](1);
        for (uint256 i = 0; i < users.length; i++) {
            _users[i] = users[i];
        }
        log(vault, _users);
    }

    function log(IERC4626 vault, address[4] memory users) public view {
        address[] memory _users = new address[](4);
        for (uint256 i = 0; i < users.length; i++) {
            _users[i] = users[i];
        }
        log(vault, _users);
    }
}
