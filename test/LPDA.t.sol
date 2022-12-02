// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {EscherTest} from "./utils/EscherTest.sol";
import {LPDAFactory, LPDA} from "src/minters/LPDAFactory.sol";

contract LPDABase is EscherTest {
    LPDAFactory public lpdaSales;
    LPDA.Sale public lpdaSale;

    function setUp() public virtual override {
        super.setUp();
        lpdaSales = new LPDAFactory();
        // set up a LPDA Sale
        lpdaSale = LPDA.Sale({
            currentId: uint48(0),
            finalId: uint48(10),
            edition: address(edition),
            startPrice: uint80(uint256(1 ether)),
            finalPrice: uint80(uint256(0.1 ether)),
            dropPerSecond: uint80(uint256(0.1 ether) / 1 days),
            startTime: uint96(block.timestamp),
            saleReceiver: payable(address(69)),
            endTime: uint96(block.timestamp + 1 days)
        });
    }
}

contract LPDAFactoryTest is LPDABase {
    function test_WhenOwner_SetFeeReceiver() public {
        assertEq(address(lpdaSales.feeReceiver()), address(this));
        lpdaSales.setFeeReceiver(payable(address(69)));
        assertEq(address(lpdaSales.feeReceiver()), address(69));
    }

    function test_RevertsWhenNotOwner_SetFeeReceiver() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        lpdaSales.setFeeReceiver(payable(address(69)));
        assertEq(address(lpdaSales.feeReceiver()), address(this));
    }

    function test_WhenOwner_TransferOwner() public {
        lpdaSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotOwner_TransferOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        lpdaSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotAdmin_CreateSale() public {
        vm.prank(address(69));
        vm.expectRevert("NOT AUTHORIZED");
        lpdaSales.createLPDASale(lpdaSale);
    }

    function test_CreateSale() public {
        lpdaSales.createLPDASale(lpdaSale);
    }
}

contract LPDATest is LPDABase {
    LPDA public sale;
    event End(LPDA.Sale _saleInfo);

    function test_Buy() public {
        sale = LPDA(lpdaSales.createLPDASale(lpdaSale));
        // authorize the lpda sale to mint tokens
        edition.grantRole(edition.MINTER_ROLE(), address(sale));
        //lets buy an NFT
        sale.buy{value: 1 ether}(1);
        assertEq(address(sale).balance, 1 ether);
    }

    function test_RevertsWhenTooSoon_Buy() public {
        test_Buy();

        rewind(1);
        vm.expectRevert("TOO SOON");
        sale.buy{value: 1 ether}(1);
    }

    function test_RevertsWhenTooLittleValue_Buy() public {
        test_Buy();

        vm.expectRevert("WRONG PRICE");
        sale.buy{value: 0 ether}(1);
    }

    function test_RevertsWhenEnded_Buy() public {
        test_Buy();

        vm.warp(lpdaSale.endTime);

        sale.buy{value: 9 ether}(9);
    }

    function test_SellsOut_Buy() public {
        test_Buy();

        sale.buy{value: 9 ether}(9);
    }

    function test_RevertsWhenSoldOut_Buy() public {
        test_SellsOut_Buy();

        vm.expectRevert("TOO MANY");
        sale.buy{value: 1 ether}(1);
    }

    function test_RevertsWhenNotOwner_Cancel() public {
        test_Buy();

        rewind(1);
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
        lpdaSale.startTime = uint96(block.timestamp + 1);
        sale = LPDA(lpdaSales.createLPDASale(lpdaSale));

        vm.prank(address(69));
        sale.cancel();
    }

    function test_Refund() public {
        test_Buy();

        vm.warp(lpdaSale.endTime + 1);
        sale.refund();
    }

    function test_WhenNotOver_Refund() public {
        test_Buy();

        vm.warp(lpdaSale.endTime - 1);
        sale.refund();
    }

    function test_RevertsWhenNoRefund_Refund() public {
        test_Buy();

        vm.warp(lpdaSale.endTime + 1);
        vm.expectRevert("NOTHING TO REFUND");
        vm.prank(address(69));
        sale.refund();
    }

    function test_RevertsWhenAlreadyRefunded_Refund() public {
        test_Refund();

        vm.expectRevert("NOTHING TO REFUND");
        sale.refund();
    }

    function test_LPDA() public {
        // make the lpda sales contract
        sale = LPDA(lpdaSales.createLPDASale(lpdaSale));
        // authorize the lpda sale to mint tokens
        edition.grantRole(edition.MINTER_ROLE(), address(sale));
        //lets buy an NFT
        sale.buy{value: 1 ether}(1);
        assertEq(address(sale).balance, 1 ether);

        vm.warp(block.timestamp + 1 days);
        assertApproxEqRel(sale.getPrice(), 0.9 ether, lpdaSale.dropPerSecond);

        // buy the rest
        // this will auto end the sale
        sale.buy{value: uint256((0.9 ether + lpdaSale.dropPerSecond) * 9)}(9);

        vm.warp(block.timestamp + 2 days);

        // now lets get a refund
        uint256 bal = address(this).balance;
        sale.refund();
        assertApproxEqRel(address(this).balance, bal + 0.1 ether, lpdaSale.dropPerSecond);
    }
}
