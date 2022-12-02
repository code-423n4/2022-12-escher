// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OpenEdition} from "./OpenEdition.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {IEscher721} from "../interfaces/IEscher721.sol";

contract OpenEditionFactory is Ownable {
    using Clones for address;

    address payable public feeReceiver;
    address public immutable implementation;

    event NewOpenEditionContract(
        address indexed creator,
        address indexed edition,
        address indexed saleContract,
        OpenEdition.Sale saleInfo
    );

    constructor() Ownable() {
        implementation = address(new OpenEdition());
        feeReceiver = payable(msg.sender);
    }

    /// @notice create a fixed sale proxy contract
    /// @param sale the sale info
    function createOpenEdition(OpenEdition.Sale calldata sale) external returns (address clone) {
        require(IEscher721(sale.edition).hasRole(bytes32(0x00), msg.sender), "NOT AUTHORIZED");
        require(sale.startTime >= block.timestamp, "START TIME IN PAST");
        require(sale.endTime > sale.startTime, "END TIME BEFORE START");

        clone = implementation.clone();
        OpenEdition(clone).initialize(sale);

        emit NewOpenEditionContract(msg.sender, sale.edition, clone, sale);
    }

    /// @notice set the fee receiver for fixed price editions
    /// @param fees the address to receive fees
    function setFeeReceiver(address payable fees) public onlyOwner {
        feeReceiver = fees;
    }
}
