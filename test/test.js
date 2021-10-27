const SimpleStorage = artifacts.require("SimpleStorage")

contract('SimpleStorage', function(accounts) {
  var tokenInstance;

  it('Contract deployed', function() {
    return SimpleStorage.deployed().then(function(instance) {
      tokenInstance = instance;
      tokenInstance.addPerson("Hello", 1);
      return tokenInstance.nameToFavoriteNumber("Hello");
    }).then(function(num) {
      assert.notEqual(num, 0, "incorrect num");
      assert.equal(num, 1, "correct num");
      tokenInstance.addPerson("World", 2);
      return tokenInstance.nameToFavoriteNumber("World");
    }).then(function(num) {
      assert.notEqual(num, 0, "incorrect num");
      assert.notEqual(num, 1, "incorrect num");
      assert.equal(num, 2, "correct num");
    });
  });
});
