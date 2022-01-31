// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeanDAO {

  //proposalDefeated and proposalSucceeded will only be used by the executor time lock contract
  function proposalDefeated(uint256 _proposalID) external returns (bool);

  function proposalSucceeded(uint256 _proposalID) external returns (bool success);

  function proposalExpired(uint256 _proposalID) external returns (bool);
}
