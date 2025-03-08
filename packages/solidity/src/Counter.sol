// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
  event NumberSet(uint256 indexed oldNumber, uint256 indexed newNumber);

  uint256 public number;

  function setNumber(uint256 newNumber) public {
    uint256 oldNumber = number;
    number = newNumber;
    emit NumberSet(oldNumber, newNumber);
  }

  function increment() public {
    uint256 oldNumber = number;
    number++;
    emit NumberSet(oldNumber, number);
  }
}
