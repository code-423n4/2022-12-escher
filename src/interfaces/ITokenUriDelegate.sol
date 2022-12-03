// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenUriDelegate {
    function initialize(address) external;

    function setBaseURI(string memory) external;

    function tokenURI(uint256) external view returns (string memory);
}
