// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISale} from "../interfaces/ISale.sol";
import {ISaleFactory} from "../interfaces/ISaleFactory.sol";
import {IEscher721} from "../interfaces/IEscher721.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract OpenEdition is Initializable, OwnableUpgradeable, ISale {
    address public immutable factory;
    /// we use different uints and some weird ordering to pack variables into 32 bytes
    struct Sale {
        // slot 1
        uint72 price;
        uint24 currentId;
        address edition;
        // slot 2
        uint96 startTime;
        address payable saleReceiver;
        // slot 3
        uint96 endTime;
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
        sale = Sale(
            type(uint72).max,
            type(uint24).max,
            address(0),
            type(uint96).max,
            payable(0),
            type(uint96).max
        );
    }

    /// @notice buy from a fixed price sale after the sale starts
    /// @param _amount the amount of editions to buy
    function buy(uint256 _amount) external payable {
        uint24 amount = uint24(_amount);
        Sale memory temp = sale;
        IEscher721 nft = IEscher721(temp.edition);
        require(block.timestamp >= temp.startTime, "TOO SOON");
        require(block.timestamp < temp.endTime, "TOO LATE");
        require(amount * sale.price == msg.value, "WRONG PRICE");
        uint24 newId = amount + temp.currentId;

        for (uint24 x = temp.currentId + 1; x <= newId; x++) {
            nft.mint(msg.sender, x);
        }
        sale.currentId = newId;

        emit Buy(msg.sender, amount, msg.value, temp);
    }

    /// @notice cancel a fixed price sale
    function cancel() external onlyOwner {
        require(block.timestamp < sale.startTime, "TOO LATE");
        _end(sale);
    }

    /// @notice initialize the proxy sale contract
    /// @param _sale the sale info
    function initialize(Sale memory _sale) public initializer {
        sale = _sale;
        _transferOwnership(sale.saleReceiver);
        emit Start(_sale);
    }

    /// @notice finish an open edition and payout the artist
    function finalize() public {
        Sale memory temp = sale;
        require(block.timestamp >= temp.endTime, "TOO SOON");
        ISaleFactory(factory).feeReceiver().transfer(address(this).balance / 20);
        _end(temp);
    }

    /// @notice the price of the sale
    function getPrice() public view returns (uint256) {
        return sale.price;
    }

    /// @notice the start time of the sale
    function startTime() public view returns (uint256) {
        return sale.startTime;
    }

    /// @notice how much time is left in the sale
    function timeLeft() public view returns (uint256) {
        return sale.endTime > block.timestamp ? sale.endTime - block.timestamp : 0;
    }

    /// @notice the edition contract having the sale
    function editionContract() public view returns (address) {
        return sale.edition;
    }

    function available() public view returns (uint256) {
        return sale.endTime > block.timestamp ? type(uint24).max : 0;
    }

    function _end(Sale memory _sale) internal {
        emit End(_sale);
        selfdestruct(_sale.saleReceiver);
    }
}
