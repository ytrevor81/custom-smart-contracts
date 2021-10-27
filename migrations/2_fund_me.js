const FundMe = artifacts.require("FundMe");

module.exports = async function(deployer) {
  await deployer.deploy(FundMe);
};
