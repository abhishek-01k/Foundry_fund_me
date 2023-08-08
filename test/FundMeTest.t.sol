// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {console} from "forge-std/console.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //The below is a dummy user created in foundry
    address USER = makeAddr("user");

    uint256 public constant GAS_PRICE = 1;
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 1 ether;

    function setUp() external {
        //contract deployment
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 10 ether); //giving 10 ether to the new user created
    }

    function testMinimumDollarFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testGetVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //below this line the code should fail then this test will pass
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // we create a new user
        fundMe.fund{value: 10e18}(); //sending the contract 10 ether
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 10e18);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        // vm.prank(fundMe.getOwner()); //test will fail because we are trying to withdraw from Owner
        vm.prank(USER); //test will pass because we are trying to withdraw from random address
        fundMe.withdraw();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testWithdrawWithASingleFunder() public funded {
        /* This test is for testing the Withdraw when only a single funder funded the contract */

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();

        uint256 gasUsed = gasStart - gasEnd;
        console.log("gas Used", gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberofFunders = 10;
        uint160 startingIndex = 2;

        for (uint160 i = startingIndex; i < numberofFunders; i++) {
            //create a address
            // give some eth to that address
            // fund the values

            // hoax is a cheat code in foundry try that
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        uint160 numberofFunders = 10;
        uint160 startingIndex = 2;

        for (uint160 i = startingIndex; i < numberofFunders; i++) {
            //create a address
            // give some eth to that address
            // fund the values

            // hoax is a cheat code in foundry try that
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.optimsedWithdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }
}
