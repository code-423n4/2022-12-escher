// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EscherTest} from "./utils/EscherTest.sol";
import {OpenEditionFactory, OpenEdition} from "src/minters/OpenEditionFactory.sol";

contract OpenEditionBase is EscherTest {
    OpenEditionFactory public openSales;
    OpenEdition.Sale public openSale;

    function setUp() public virtual override {
        super.setUp();
        openSales = new OpenEditionFactory();
        openSale = OpenEdition.Sale({
            price: uint72(uint256(1 ether)),
            currentId: uint24(1),
            edition: address(edition),
            startTime: uint96(block.timestamp),
            saleReceiver: payable(address(69)),
            endTime: uint96(block.timestamp + 1 days)
        });
    }
}

contract OpenEditionFactoryTest is OpenEditionBase {
    function test_WhenOwner_SetFeeReceiver() public {
        assertEq(address(openSales.feeReceiver()), address(this));
        openSales.setFeeReceiver(payable(address(69)));
        assertEq(address(openSales.feeReceiver()), address(69));
    }

    function test_RevertsWhenNotOwner_SetFeeReceiver() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        openSales.setFeeReceiver(payable(address(69)));
        assertEq(address(openSales.feeReceiver()), address(this));
    }

    function test_WhenOwner_TransferOwner() public {
        openSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotOwner_TransferOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(69));
        openSales.transferOwnership(address(69));
    }

    function test_RevertsWhenNotAdmin_CreateSale() public {
        vm.prank(address(69));
        vm.expectRevert("NOT AUTHORIZED");
        openSales.createOpenEdition(openSale);
    }

    function test_CreateSale() public {
        openSales.createOpenEdition(openSale);
    }
}

contract OpenEditionImplementation is OpenEditionBase {
    OpenEdition public implementation;

    function setUp() public override {
        super.setUp();
        implementation = OpenEdition(openSales.implementation());
    }

    function test_RevertsWhenInitialized_Initialize() public {
        vm.expectRevert("Initializable: contract is already initialized");
        implementation.initialize(openSale);
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

    function test_RevertsWhenInitialized_Finalize() public {
        vm.expectRevert("TOO SOON");
        implementation.finalize();
    }
}

contract OpenEditionTest is OpenEditionBase {
    OpenEdition public sale;
    event End(OpenEdition.Sale _saleInfo);

    function test_Buy() public {
        sale = OpenEdition(openSales.createOpenEdition(openSale));
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

    function test_RevertsWhenEnded_Buy() public {
        test_Buy();
        vm.warp(openSale.endTime);

        vm.expectRevert("TOO LATE");
        sale.buy{value: 9 ether}(9);
    }

    function test_RevertsWhenNotEnded_Finalize() public {
        test_Buy();
        vm.warp(openSale.endTime - 1);

        vm.expectRevert("TOO SOON");
        sale.finalize();
    }

    function test_WhenEnded_Finalize() public {
        test_Buy();
        vm.warp(openSale.endTime);

        sale.finalize();
    }

    function test_RevertsWhenNotOwner_TransferOwnership() public {
        test_Buy();

        vm.expectRevert("Ownable: caller is not the owner");
        sale.transferOwnership(address(1));
        assertEq(sale.owner(), openSale.saleReceiver);
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
        openSale.startTime = uint96(block.timestamp + 1);
        sale = OpenEdition(openSales.createOpenEdition(openSale));

        vm.prank(address(69));
        sale.cancel();
    }
}
