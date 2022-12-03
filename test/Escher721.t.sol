// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {EscherTest} from "./utils/EscherTest.sol";

contract Escher721Test is EscherTest {
    function setUp() public override {
        super.setUp();
    }

    function test_UpdateURIDelegate() public {
        edition.updateURIDelegate(address(0));
    }

    function test_RevertsWhenNotCreator_UpdateURIDelegate() public {
        vm.prank(address(69));
        vm.expectRevert();
        edition.updateURIDelegate(address(0));
    }
}
