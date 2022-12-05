// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {EscherTest} from "./utils/EscherTest.sol";
import {FixedPriceFactory, FixedPrice} from "src/minters/FixedPriceFactory.sol";

contract FixedPriceBaseTest is EscherTest {
    FixedPrice.Sale public fixedSale;
    FixedPriceFactory public fixedSales;

    function setUp() public virtual override {
        super.setUp();
        fixedSales = new FixedPriceFactory();
        fixedSale = FixedPrice.Sale({
            currentId: uint48(0),
            finalId: uint48(10),
            edition: address(edition),
            price: uint96(uint256(1 ether)),
            saleReceiver: payable(address(69)),
            startTime: uint96(block.timestamp)
        });
    }
}

contract FactoryTest is FixedPriceBaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_WhenOwner_SetFeeReceiver() public {
        assertEq(address(fixedSales.feeReceiver()), address(this));
        fixedSales.setFeeReceiver(payable(address(69)));
        assertEq(address(fixedSales.feeReceiver()), address(69));
    }

    function test_RevertsWhenNotOwner_SetFeeReceiver() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        fixedSales.setFeeReceiver(payable(address(69)));
        assertEq(address(fixedSales.feeReceiver()), address(this));
    }

    function test_WhenOwner_TransferOwner() public {
        fixedSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotOwner_TransferOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        fixedSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotAdmin_CreateSale() public {
        vm.prank(address(69));
        vm.expectRevert("NOT AUTHORIZED");
        fixedSales.createFixedSale(fixedSale);
    }

    function test_CreateSale() public {
        fixedSales.createFixedSale(fixedSale);
    }
}

contract FixedPriceImplementationTest is FixedPriceBaseTest {
    FixedPrice public implementation;

    function setUp() public override {
        super.setUp();
        implementation = FixedPrice(fixedSales.implementation());
    }

    function test_RevertsWhenInitialized_Initialize() public {
        vm.expectRevert("Initializable: contract is already initialized");
        implementation.initialize(fixedSale);
    }

    function test_RevertsWhenInitialized_Buy() public {
        vm.expectRevert("TOO SOON");
        implementation.buy{value: 0}(0);
    }

    function test_RevertsWhenInitialized_TransferOwnership() public {
        vm.expectRevert("Ownable: caller is not the owner");
        implementation.transferOwnership(address(1));
        assertEq(implementation.owner(), address(0));
    }

    function test_RevertsWhenInitialized_Cancel() public {
        vm.expectRevert("Ownable: caller is not the owner");
        implementation.cancel();
    }
}

contract FixedPriceTest is FixedPriceBaseTest {
    FixedPrice public sale;
    event End(FixedPrice.Sale _saleInfo);

    mapping(uint256 => address) ownersOf;
    uint256 startId;
    uint256 finalId;
    uint256 currentId;

    function setUp() public override {
        super.setUp();
    }

    function test_Buy() public {
        // make the fixed price sale
        sale = FixedPrice(fixedSales.createFixedSale(fixedSale));
        // authorize the fixed price sale to mint tokens
        edition.grantRole(edition.MINTER_ROLE(), address(sale));
        // lets buy some NFTs
        sale.buy{value: 1 ether}(1);
        assertEq(address(sale).balance, 1 ether);
    }

    function test_RevertsWhenTooSoon_Buy() public {
        test_Buy();

        rewind(1);
        vm.expectRevert("TOO SOON");
        sale.buy{value: 1 ether}(1);
    }

    function test_RevertsWhenTooMany_Buy() public {
        test_Buy();

        vm.expectRevert("TOO MANY");
        sale.buy{value: 11 ether}(11);
    }

    function test_RevertsWhenTooLittleValue_Buy() public {
        test_Buy();

        vm.expectRevert("WRONG PRICE");
        sale.buy{value: 0 ether}(1);
    }

    function test_RevertsTooMuchValue_Buy() public {
        test_Buy();

        vm.expectRevert("WRONG PRICE");
        sale.buy{value: 2 ether}(1);
    }

    function test_WhenMintsOut_Buy() public {
        test_Buy();
        uint256 cached_balance = address(this).balance - 9 ether;

        // set sale state to be emitted
        fixedSale.currentId = uint48(10);
        vm.expectEmit(true, true, false, true);
        emit End(fixedSale);
        sale.buy{value: 9 ether}(9);
        assertEq(address(69).balance, 9.5 ether);
        assertEq(address(this).balance - cached_balance, 0.5 ether);
    }

    function test_RevertsWhenMintedOut_Buy() public {
        test_WhenMintsOut_Buy();

        vm.expectRevert();
        sale.buy{value: 1 ether}(1);
    }

    function test_RevertsWhenNotOwner_TransferOwnership() public {
        test_Buy();

        vm.expectRevert("Ownable: caller is not the owner");
        sale.transferOwnership(address(1));
        assertEq(sale.owner(), fixedSale.saleReceiver);
    }

    function test_RevertsWhenNotOwner_Cancel() public {
        test_Buy();

        vm.expectRevert("Ownable: caller is not the owner");
        sale.cancel();
    }

    function test_RevertsWhenTooLate_Cancel() public {
        test_Buy();

        vm.prank(address(69));
        vm.expectRevert("TOO LATE");
        sale.cancel();
    }

    function test_Cancel() public {
        fixedSale.startTime = uint96(block.timestamp + 1);
        // make the fixed price sale
        sale = FixedPrice(fixedSales.createFixedSale(fixedSale));
        // authorize the fixed price sale to mint tokens
        edition.grantRole(edition.MINTER_ROLE(), address(sale));
        // lets buy some NFTs
        vm.prank(address(69));
        sale.cancel();
    }
}
