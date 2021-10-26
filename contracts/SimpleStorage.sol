pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
  uint256 public favoriteNumber;
  //bool favoriteBool = true;
  //string favoriteString = "Yo";
  //int256 favoriteInt = 5; //int can be positive or negative
  //address favoriteAddress = ;
  //bytes32 favoriteBytes = "cat";

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

}
