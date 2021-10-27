const StorageFactory = artifacts.require("StorageFactory")

contract('StorageFactory', function(accounts) {
  var contractInstance;

  it('Contract deployed', function() {
    return StorageFactory.deployed().then(function(instance) {
      contractInstance = instance;
      contractInstance.createSimpleStorageContract();
      contractInstance.sfStore(0, 31);
      return contractInstance.sfGet(0);
    }).then(function(num) {
      assert.notEqual(num, 0, "incorrect num");
      assert.equal(num, 31, "correct num");
    });
  });
});
