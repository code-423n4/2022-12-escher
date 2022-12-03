// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FixedPrice} from "./FixedPrice.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {IEscher721} from "../interfaces/IEscher721.sol";

contract FixedPriceFactory is Ownable {
    using Clones for address;

    address payable public feeReceiver;
    address public immutable implementation;

    event NewFixedPriceContract(
        address indexed creator,
        address indexed edition,
        address indexed saleContract,
        FixedPrice.Sale saleInfo
    );

    constructor() Ownable() {
        implementation = address(new FixedPrice());
        feeReceiver = payable(msg.sender);
    }

    /// @notice create a fixed sale proxy contract
    /// @param _sale the sale info
    function createFixedSale(FixedPrice.Sale calldata _sale) external returns (address clone) {
        require(IEscher721(_sale.edition).hasRole(bytes32(0x00), msg.sender), "NOT AUTHORIZED");
        require(_sale.startTime >= block.timestamp, "START TIME IN PAST");
        require(_sale.finalId > _sale.currentId, "FINAL ID BEFORE CURRENT");

        clone = implementation.clone();
        FixedPrice(clone).initialize(_sale);

        emit NewFixedPriceContract(msg.sender, _sale.edition, clone, _sale);
    }

    /// @notice set the fee receiver for fixed price editions
    /// @param fees the address to receive fees
    function setFeeReceiver(address payable fees) public onlyOwner {
        feeReceiver = fees;
    }
}
