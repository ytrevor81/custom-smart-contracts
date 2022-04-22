// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrevToken  {

  function getBlackListStatus(address _user) external view returns(bool);

  function mintFromDAO(uint256 amount) external;

}
