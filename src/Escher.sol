// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "openzeppelin/token/ERC1155/ERC1155.sol";
import {AccessControl} from "openzeppelin/access/AccessControl.sol";

/// @title Escher
/// @notice Escher is a decentralized curated marketplace for editionized artworks
contract Escher is ERC1155, AccessControl {
    /// @notice The role that grants the ability to mint editions
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    /// @notice the role that grants the ability to onboard creators
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Updates the metadata for Escher Solbound token
    /// @param _newuri The new metadata URI
    function setURI(string memory _newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_newuri);
    }

    /// @notice Adds a new creator to Escher
    /// @param _account The creator's account to onboard
    function addCreator(address _account) public onlyRole(CURATOR_ROLE) {
        _grantRole(CREATOR_ROLE, _account);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice SoulBound
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("SoulBound");
    }

    /// @notice SoulBound
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("SoulBound");
    }

    /// @notice Receive a role, get a token
    function _grantRole(bytes32 _role, address _account) internal override {
        require(balanceOf(_account, uint256(_role)) == 0, "Already Creator");
        super._grantRole(_role, _account);
        _mint(_account, uint256(_role), 1, "0x0");
    }

    /// @notice Lose a role, burn a token
    function _revokeRole(bytes32 _role, address _account) internal override {
        super._revokeRole(_role, _account);
        _burn(_account, uint256(_role), balanceOf(_account, uint256(_role)));
    }
}
