// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // Script that deploy the FundMe contract
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol"; // Script that interact with FundMe contract (i.e, funding and withdrawing)

contract InteractionTest is Test {
    FundMe fundMe;

    //The below is a dummy user created in foundry
    address USER = makeAddr("user");

    uint256 public constant GAS_PRICE = 1;
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testUserCanFundInteractions() external {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
