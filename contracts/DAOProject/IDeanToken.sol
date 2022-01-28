// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeanToken  {

  function getBlackListStatus(address _user) external view returns(bool);

  //Governor address of DeanDAO protocal call call these functions
  function addToBlackList(address _user) external;

  function removeFromBlackList (address _user) external;
}
