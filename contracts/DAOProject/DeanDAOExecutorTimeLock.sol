// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IDeanDAOExecutorTimeLock.sol";

contract DeanDAOExecutorTimeLock is IDeanDAOExecutorTimeLock {

  uint public constant duration = 365 days;
  uint public immutable end;

  constructor() {
    end = block.timestamp + duration;
  }

  function seeBlockTime() external view returns (uint) {
    return block.timestamp;
  }
}
