// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LPDA} from "./LPDA.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {IEscher721} from "../interfaces/IEscher721.sol";

contract LPDAFactory is Ownable {
    using Clones for address;

    address payable public feeReceiver;
    address public immutable implementation;

    event NewLPDAContract(
        address indexed _creator,
        address indexed _edition,
        address indexed _saleContract,
        LPDA.Sale _saleInfo
    );

    constructor() Ownable() {
        implementation = address(new LPDA());
        feeReceiver = payable(msg.sender);
    }

    /// @notice create a fixed sale proxy contract
    /// @param sale the sale info
    function createLPDASale(LPDA.Sale calldata sale) external returns (address clone) {
        require(IEscher721(sale.edition).hasRole(bytes32(0x00), msg.sender), "NOT AUTHORIZED");
        require(sale.saleReceiver != address(0), "INVALID SALE RECEIVER");
        require(sale.startTime >= block.timestamp, "INVALID START TIME");
        require(sale.endTime > sale.startTime, "INVALID END TIME");
        require(sale.finalId > sale.currentId, "INVALID FINAL ID");
        require(sale.startPrice > 0, "INVALID START PRICE");
        require(sale.dropPerSecond > 0, "INVALID DROP PER SECOND");

        clone = implementation.clone();
        LPDA(clone).initialize(sale);

        emit NewLPDAContract(msg.sender, sale.edition, clone, sale);
    }

    /// @notice set the fee receiver for fixed price editions
    /// @param fees the address to receive fees
    function setFeeReceiver(address payable fees) public onlyOwner {
        feeReceiver = fees;
    }
}
