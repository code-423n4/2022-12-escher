// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISale} from "../interfaces/ISale.sol";
import {ISaleFactory} from "../interfaces/ISaleFactory.sol";
import {IEscher721} from "../interfaces/IEscher721.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract FixedPrice is Initializable, OwnableUpgradeable, ISale {
    address public immutable factory;
    /// store nextId and remainingSupply, where nextId increases and remainingSupply decreases to 0
    /// avoids strict equality of current == final
    struct Sale {
        // slot 1
        uint48 currentId;
        uint48 finalId;
        address edition;
        // slot 2
        uint96 price;
        address payable saleReceiver;
        // slot 3
        uint96 startTime;
    }

    /// @notice sale info for this fixed price edition
    Sale public sale;

    /// @notice Event emitted when sale created
    /// @param _saleInfo the sale info for the edition
    event Start(Sale _saleInfo);
    /// @notice Event emitted when sale ends
    /// @param _saleInfo the sale info for the edition
    event End(Sale _saleInfo);
    /// @notice Event emitted when a user buys an edition
    /// @param _buyer the address of the buyer
    /// @param _amount the amount of editions bought
    /// @param _value the total value of the purchase
    /// @param _saleInfo the sale info for the edition
    event Buy(address indexed _buyer, uint256 _amount, uint256 _value, Sale _saleInfo);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        factory = msg.sender;
        _disableInitializers();
        sale = Sale(0, 0, address(0), type(uint96).max, payable(0), type(uint96).max);
    }

    /// @notice Owner can cancel current sale
    function cancel() external onlyOwner {
        require(block.timestamp < sale.startTime, "TOO LATE");
        _end(sale);
    }

    /// @notice buy from a fixed price sale after the sale starts
    /// @param _amount the amount of editions to buy
    function buy(uint256 _amount) external payable {
        Sale memory sale_ = sale;
        IEscher721 nft = IEscher721(sale_.edition);
        require(block.timestamp >= sale_.startTime, "TOO SOON");
        require(_amount * sale_.price == msg.value, "WRONG PRICE");
        uint48 newId = uint48(_amount) + sale_.currentId;
        require(newId <= sale_.finalId, "TOO MANY");

        for (uint48 x = sale_.currentId + 1; x <= newId; x++) {
            nft.mint(msg.sender, x);
        }

        sale.currentId = newId;

        emit Buy(msg.sender, _amount, msg.value, sale);

        if (newId == sale_.finalId) _end(sale);
    }

    /// @notice initialize the proxy sale contract
    /// @param _sale the sale info
    function initialize(Sale memory _sale) public initializer {
        sale = _sale;
        _transferOwnership(_sale.saleReceiver);
        emit Start(_sale);
    }

    /// @notice cancel a fixed price sale
    /// @notice the price of the sale
    function getPrice() public view returns (uint256) {
        return sale.price;
    }

    /// @notice the start time of the sale
    function startTime() public view returns (uint256) {
        return sale.startTime;
    }

    /// @notice the edition contract having the sale
    function editionContract() public view returns (address) {
        return sale.edition;
    }

    /// @notice the number of NFTs still available
    function available() public view returns (uint256) {
        return sale.finalId - sale.currentId;
    }

    /// @notice Owner can cancel current sale
    /// @param _sale the sale info
    function _end(Sale memory _sale) internal {
        emit End(_sale);
        ISaleFactory(factory).feeReceiver().transfer(address(this).balance / 20);
        selfdestruct(_sale.saleReceiver);
    }
}
