// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Escher} from "./Escher.sol";
import {Escher721} from "./Escher721.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {ITokenUriDelegate} from "./interfaces/ITokenUriDelegate.sol";

contract Escher721Factory {
    using Clones for address;

    Escher public immutable escher;
    address public immutable implementation;

    event NewEscher721Contract(address indexed creator, address indexed clone, address indexed uri);

    constructor(address _escher) {
        escher = Escher(_escher);
        implementation = address(new Escher721());
        Escher721(implementation).initialize(address(this), address(0), "Implementation", "IMPL");
    }

    /// @notice create a new escher unique contract
    /// @param _name the name of the contract
    /// @param _symbol the symbol of the contract
    /// @param _uri the uri delegate contract
    function createContract(
        string memory _name,
        string memory _symbol,
        address _uri
    ) external returns (address escherClone) {
        require(escher.hasRole(escher.CREATOR_ROLE(), msg.sender), "NOT AUTHORIZED");

        escherClone = implementation.clone();
        address uriClone = _uri.clone();

        Escher721(escherClone).initialize(msg.sender, uriClone, _name, _symbol);
        ITokenUriDelegate(uriClone).initialize(msg.sender);

        emit NewEscher721Contract(msg.sender, escherClone, uriClone);
    }
}
