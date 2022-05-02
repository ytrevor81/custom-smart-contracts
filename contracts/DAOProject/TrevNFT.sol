// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TrevNFT is ERC721URIStorage {

    uint256 public tokenCounter;

    constructor() ERC721("TrevNFT", "TNFT") {
        tokenCounter ++;
        _safeMint(msg.sender, tokenCounter);
    }
}
