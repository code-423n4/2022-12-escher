// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {Escher} from "src/Escher.sol";
import {Escher721Factory, Escher721} from "src/Escher721Factory.sol";

import "openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";

contract EscherTest is Test, ERC721Holder, ERC1155Holder {
    Escher public escher;
    Escher721Factory public editions;
    Escher721 public edition;

    function setUp() public virtual {
        escher = new Escher();
        editions = new Escher721Factory(address(escher));
        // set us up as a creator
        escher.grantRole(escher.CURATOR_ROLE(), address(this));
        escher.addCreator(address(this));
        //
        // make our editions contract
        edition = Escher721(editions.createContract("Test", "TEST", address(0)));
    }

    receive() external payable {}
}
