// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeanToken  {

  function getBlackListStatus(address _user) external view returns(bool);

}
