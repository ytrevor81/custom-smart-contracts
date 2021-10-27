// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
  uint256 favoriteNumber;
  //bool favoriteBool = true;
  //string favoriteString = "Yo";
  //int256 favoriteInt = 5; //int can be positive or negative
  //address favoriteAddress = ;
  //bytes32 favoriteBytes = "cat";

  struct People {
    uint256 num;
    string name;
  }

  //People public person = People({num: 69, name: "Yo Momma"});
  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns(uint256){
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }

  //function doubleFavNum(uint256 favoriteNumber) public pure {
  //  favoriteNumber + favorite
  //}

  //view, pure keywords dont require transactions

}
