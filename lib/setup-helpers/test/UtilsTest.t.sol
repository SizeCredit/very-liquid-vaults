// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Utils} from "../src/Utils.sol";
import {Panic} from "../src/Panic.sol";

contract Thrower {
    uint8[] public array;

    error SimpleCustomError();
    error ComplexCustomError(string message);

    enum TestEnum {
        A,
        B
    }

    function assertionPanic() public pure {
        assert(false);
    }

    function arithmeticPanic() public pure {
        uint8 x = 255;
        x += 1;
    }

    function divisionPanic() public pure {
        uint256 x = 1;
        x = x / 0;
    }

    function enumPanic() public pure {
        TestEnum x;
        assembly {
            // Force x to have value 2, which is invalid for the enum
            mstore(0x00, 2)
            x := mload(0x00)
        }
        // The line below will panic because x has an invalid value
        x;
    }

    function arrayPanic() public {
        // This is harder to trigger directly in a test environment
        // Usually happens with corrupted storage
        assembly {
            sstore(0, "bad data")
        }
        array.pop();
    }

    function emptyArrayPanic() public {
        array.pop(); // Pop from empty array
    }

    function outOfBoundsPanic() public {
        array.push(1);
        array[1]; // Access index 1 when length is 1
    }

    function memoryPanic() public pure {
        uint256[] memory arr = new uint256[](2 ** 64); // Too large
    }

    function functionPanic() public {
        function() internal pure fp;
        fp(); // Call uninitialized function pointer
    }

    function revertWithoutString() public pure {
        revert();
    }

    function revertWithString() public pure {
        revert("custom revert message");
    }

    function revertWithSimpleCustomError() public pure {
        revert SimpleCustomError();
    }

    function revertWithComplexCustomError() public pure {
        revert ComplexCustomError("complex error message");
    }

    function revertWithRequire() public pure {
        require(false);
    }

    function revertWithRequireMessage() public pure {
        require(false, "require message");
    }
}

contract UtilsTest is Test, Utils {
    Thrower thrower;

    function setUp() public {
        thrower = new Thrower();
    }

    function test_assertionPanic() public {
        try thrower.assertionPanic() {}
        catch (bytes memory err) {
            bool expectedError;
            expectedError = checkError(err, Panic.assertionPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_arithmeticPanic() public {
        try thrower.arithmeticPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.arithmeticPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_divisionPanic() public {
        try thrower.divisionPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.divisionPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_enumPanic() public {
        try thrower.enumPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.enumPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_arrayPanic() public {
        try thrower.arrayPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.arrayPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_emptyArrayPanic() public {
        try thrower.emptyArrayPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.emptyArrayPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_outOfBoundsPanic() public {
        try thrower.outOfBoundsPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.outOfBoundsPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_memoryPanic() public {
        try thrower.memoryPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.memoryPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_functionPanic() public {
        try thrower.functionPanic() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, Panic.functionPanic);
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithoutString() public {
        try thrower.revertWithoutString() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "");
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithString() public {
        try thrower.revertWithString() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "custom revert message");
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithSimpleCustomError() public {
        try thrower.revertWithSimpleCustomError() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "SimpleCustomError()");
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithComplexCustomError() public {
        try thrower.revertWithComplexCustomError() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "ComplexCustomError(string)");
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithRequire() public {
        try thrower.revertWithRequire() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "");
            assertTrue(expectedError, "unexpected error");
        }
    }

    function test_revertWithRequireMessage() public {
        try thrower.revertWithRequireMessage() {}
        catch (bytes memory err) {
            bool expectedError = checkError(err, "require message");
            assertTrue(expectedError, "unexpected error");
        }
    }
}
