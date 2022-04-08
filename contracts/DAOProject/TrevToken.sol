// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITrevToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrevToken is ERC20, Ownable, ITrevToken {

  constructor() ERC20("Trev Token", "TTK") {
    _mint(_msgSender(), 1000000 * 10 ** uint256(decimals()));
  }

  mapping (address => bool) private isBlackListed;

  event AddedBlackList (address indexed _user);
  event RemovedBlackList (address indexed _user);

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(isBlackListed[_msgSender()] == false, "Sender is on BlackList");
    require(isBlackListed[recipient] == false, "Recipient is on BlackList");
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function mint (address account, uint256 amount) public onlyOwner {
    _mint(account, amount);
  }

  function getBlackListStatus(address _user) external view override returns(bool) {
    return isBlackListed[_user];
  }

  function addToBlackList(address _user) external onlyOwner {
    isBlackListed[_user] = true;
    emit AddedBlackList(_user);
  }

  function removeFromBlackList (address _user) external onlyOwner {
    isBlackListed[_user] = false;
    emit RemovedBlackList(_user);
  }
}
