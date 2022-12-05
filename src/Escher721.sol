// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenUriDelegate} from "./interfaces/ITokenUriDelegate.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import {AccessControlUpgradeable} from "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";

contract Escher721 is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    ERC2981Upgradeable
{
    /// @notice The role to update the URI delegate
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    /// @notice The role to mint editionized art work
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice The URI delegate address
    address public tokenUriDelegate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /// @notice initialize the proxy contract
    /// @param _creator the initial admin for the contract
    /// @param _uri the address of the token URI delegate
    /// @param _name the name of this contract
    /// @param _symbol the symbol of this contract
    function initialize(
        address _creator,
        address _uri,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();

        tokenUriDelegate = _uri;

        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _grantRole(MINTER_ROLE, _creator);
        _grantRole(URI_SETTER_ROLE, _creator);
    }

    /// @notice mint a token
    /// @param to who to mint the token to
    /// @param tokenId the token ID to mint
    function mint(address to, uint256 tokenId) public virtual onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    /// @notice update the URI delegate contract
    /// @param _uriDelegate The new tokenURIDelegate address
    function updateURIDelegate(address _uriDelegate) public onlyRole(URI_SETTER_ROLE) {
        tokenUriDelegate = _uriDelegate;
    }

    /// @notice set the default royalty for a contract
    /// @param receiver the address who receives royalties
    /// @param feeNumerator the royalty percentage
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice resets default royalties
    function resetDefaultRoyalty() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /// @notice Getter for the token URI
    /// @param _tokenId the token ID to get the URI for
    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        return ITokenUriDelegate(tokenUriDelegate).tokenURI(_tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }
}
