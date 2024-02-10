// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SampleCoin is ERC20 {
    // your code goes here (you can do it!)

    address public owner;

    constructor() ERC20("SampleCoin", "SampleCoin") {
        owner = msg.sender;
        _mint(owner, 100000000000000000000);
    }

    function mint(uint128 amount) external {
        _mint(msg.sender, amount);
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
}