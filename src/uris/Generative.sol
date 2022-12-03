// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Unique} from "./Unique.sol";

contract Generative is Unique {
    bytes32 public seedBase;
    /// @notice mapping used to store the generative script
    mapping(uint256 => string) public scriptPieces;

    /// @notice set the prices for a generative script
    /// @param _id the id in the mapping to set
    /// @param _data generative script data
    function setScriptPiece(uint256 _id, string memory _data) external onlyOwner {
        require(bytes(scriptPieces[_id]).length == 0, "ALREADY SET");
        scriptPieces[_id] = _data;
    }

    function setSeedBase() external onlyOwner {
        require(seedBase == bytes32(0), "SEED BASE SET");

        uint256 time = block.timestamp;
        uint256 numb = block.number;
        seedBase = keccak256(abi.encodePacked(numb, blockhash(numb - 1), time, (time % 200) + 1));
    }

    function tokenToSeed(uint256 _tokenId) internal view returns (bytes32) {
        require(seedBase != bytes32(0), "SEED BASE NOT SET");
        return keccak256(abi.encodePacked(_tokenId, seedBase));
    }
}
