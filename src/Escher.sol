// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "openzeppelin/token/ERC1155/ERC1155.sol";
import {AccessControl} from "openzeppelin/access/AccessControl.sol";

contract Escher is ERC1155, AccessControl {
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function addCreator(address account) public onlyRole(CURATOR_ROLE) {
        _grantRole(CREATOR_ROLE, account);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("SoulBound");
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("SoulBound");
    }

    function _grantRole(bytes32 role, address account) internal override {
        require(balanceOf(account, uint256(role)) == 0, "Already Creator");
        super._grantRole(role, account);
        _mint(account, uint256(role), 1, "0x0");
    }

    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _burn(account, uint256(role), balanceOf(account, uint256(role)));
    }
}
