const StorageFactory = artifacts.require("StorageFactory");

module.exports = async function(deployer) {
  await deployer.deploy(StorageFactory);
};
