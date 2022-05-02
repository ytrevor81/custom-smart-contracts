// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrevTokenAirDrop {

    address public  immutable trevTokenAddress;
    address public immutable trevNFTAddress;

    uint256 private immutable amountPerAirdrop;

    mapping(address => bool) public addressAlreadyReceivedAirdrop;

    event AirDropped(uint256 _amount, address _to);

    constructor(address _trevTokenAddress, address _trevNFTAddress) {
        trevTokenAddress = _trevTokenAddress;
        trevNFTAddress = _trevNFTAddress;
        amountPerAirdrop = 1500 * 10 ** 18;
    }

    function seeBalenceOfContract() public view returns (uint256) {
    uint256 currentBalence = IERC20(trevTokenAddress).balanceOf(address(this));
    return currentBalence;
    }

    function airDrop() external returns (bool) {
        uint256 currentBalence = seeBalenceOfContract();
        bool hasNFT = userHasNFT();
        address _sender = msg.sender;

        require(addressAlreadyReceivedAirdrop[_sender] == false, "User already had an airdrop of TTK");
        require(currentBalence >= amountPerAirdrop, "Contract has less than the airdrop amount");
        require(hasNFT == true, "User doesn't have a TNFT");

        IERC20(trevTokenAddress).transfer(_sender, amountPerAirdrop);
        addressAlreadyReceivedAirdrop[_sender] = true;

        emit AirDropped(amountPerAirdrop, _sender);

        return true;
    }

    function userHasNFT() public view returns (bool) {
        uint256 amountOfNFTsOwned =  IERC721(trevNFTAddress).balanceOf(msg.sender);
        if (amountOfNFTsOwned > 0) {
            return true;
        }

        return false;
    }


}
