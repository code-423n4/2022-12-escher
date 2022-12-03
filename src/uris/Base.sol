// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenUriDelegate} from "../interfaces/ITokenUriDelegate.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract Base is ITokenUriDelegate, OwnableUpgradeable {
    string public baseURI;

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256) external view virtual returns (string memory) {
        return baseURI;
    }

    function initialize(address _owner) public initializer {
        _transferOwnership(_owner);
    }
}
