// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TrevNFT is ERC721URIStorage {

    uint256 public immutable maximumNumOfNFTs;
    address public immutable governor;
    uint256 private _tokenCounter;

    enum NFTType {RETRO, PHILOSOPHICAL, FANCY} //returns 0, 1, 2

    mapping(uint256 => NFTType) public tokenType; //maps tokenID to NFTType
    mapping(uint256 => bool) public tokenURISet; //maps tokenID to boolean, true if token URI was already set

    event NFTTypeAssigned(uint256 indexed tokenId, NFTType nftType);
    event TokenURIAssigned(uint256 indexed tokenId, string tokenURI);
    event GovernorChanged(address indexed _governor);

    constructor(uint256 _maximumNumOfNFTs) ERC721("TrevNFT", "TNFT") {
        maximumNumOfNFTs = _maximumNumOfNFTs;
        governor = msg.sender;
        _tokenCounter = 0;
    }

    /**
    * mintNFT takes in a random number to randomize the generation of each NFT
    **/

    function mintNFT(uint256 randomNumber) external returns (bool) {
        require(_tokenCounter < maximumNumOfNFTs, "Cannot mint any more NFTs");
        _tokenCounter++;
        assignNFTType(randomNumber);
        _safeMint(msg.sender, _tokenCounter);
        return true;
    }

  function assignNFTType (uint256 randomNumber) internal {
      NFTType nftType = NFTType(randomNumber % 3); //randomly generated NFT Type
      tokenType[_tokenCounter] = nftType;
      emit NFTTypeAssigned(_tokenCounter, nftType);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external returns (bool) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "NFT caller is not owner");
      require(tokenURISet[tokenId] == false, "NFT URI already set");
      _setTokenURI(tokenId, _tokenURI);
      tokenURISet[tokenId] = true;
      emit TokenURIAssigned(tokenId, _tokenURI);
      return true;
  }

  function tokenCounter() external view returns (uint256){
      require(msg.sender == governor, "Caller is not owner.");
      return _tokenCounter;
  }
}
