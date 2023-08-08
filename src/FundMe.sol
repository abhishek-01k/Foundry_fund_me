// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // the variables in the sc are stored in storage and calling them from storage cost a lot
    // Also constant and immutables are not stored in storage

    /*
        1. We should avoid calling storage again and again in a function instead use call from memory.
        2. Calling from storage cost a lot of gas while from memory it is quiet cheap.
    */

    mapping(address => uint256) private addressToAmountFunded;
    address[] private funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // The below function will give cheaper withdraw
    function optimsedWithdraw() public onlyOwner {
        uint256 funderLength = funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < funderLength; // here funders is stored in storage
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length; // here funders is stored in storage
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getFunders(uint256 funder_index) public view returns (address) {
        return funders[funder_index];
    }

    function getAddressToAmountFunded(
        address funder_address
    ) public view returns (uint256) {
        return addressToAmountFunded[funder_address];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
