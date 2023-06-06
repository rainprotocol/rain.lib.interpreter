// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "src/LibParse.sol";

contract LibParseNamedRHSTest is Test {
    function testParseNamedRHSSimple() external {
        string[3] memory examples0 = ["_:a();", "_ _:a() b();", "foo bar: a() b();"];
        for (uint256 i = 0; i < examples0.length; i++) {
            (bytes[] memory sources0, uint256[] memory constants0) = LibParse.parse(bytes(examples0[i]));
            assertEq(sources0.length, 1);
            assertEq(sources0[0].length, 0);
            assertEq(constants0.length, 0);
        }

        (bytes[] memory sources1, uint256[] memory constants1) = LibParse.parse("a:;b:;");
        assertEq(sources1.length, 2);
        assertEq(sources1[0].length, 0);
        assertEq(sources1[1].length, 0);
        assertEq(constants1.length, 0);
    }

    // function testParseNamedGas00() external pure {
    //     LibParse.parse("a:;");
    // }

    // function testParseNamedGas01() external pure {
    //     LibParse.parse("a:;");
    // }

    // function testParseNamedGas02() external pure {
    //     LibParse.parse("aa:;");
    // }

    // function testParseNamedGas03() external pure {
    //     LibParse.parse("aaa:;");
    // }

    // function testParseNamedGas04() external pure {
    //     LibParse.parse("aaaa:;");
    // }

    // function testParseNamedGas05() external pure {
    //     LibParse.parse("aaaaa:;");
    // }

    // function testParseNamedGas06() external pure {
    //     LibParse.parse("aaaaaa:;");
    // }

    // function testParseNamedGas07() external pure {
    //     LibParse.parse("aaaaaaa:;");
    // }

    // function testParseNamedGas08() external pure {
    //     LibParse.parse("aaaaaaaa:;");
    // }

    // function testParseNamedGas09() external pure {
    //     LibParse.parse("aaaaaaaaa:;");
    // }

    // function testParseNamedGas10() external pure {
    //     LibParse.parse("aaaaaaaaaa:;");
    // }

    // function testParseNamedGas11() external pure {
    //     LibParse.parse("aaaaaaaaaaa:;");
    // }

    // function testParseNamedGas12() external pure {
    //     LibParse.parse("aaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas13() external pure {
    //     LibParse.parse("aaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas14() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas15() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas16() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas17() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas18() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas19() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas20() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas21() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas22() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas23() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas24() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas25() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas26() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas27() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas28() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas29() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas30() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas31() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas32() external pure {
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }

    // function testParseNamedGas33() external {
    //     vm.expectRevert(abi.encodeWithSelector(WordTooLong.selector, 0));
    //     LibParse.parse("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:;");
    // }
}