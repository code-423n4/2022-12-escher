// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Base} from "./Base.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract Unique is Base {
    using Strings for uint256;

    function tokenURI(uint256 _tokenId) external view virtual override returns (string memory) {
        return string.concat(baseURI, _tokenId.toString());
    }
}
