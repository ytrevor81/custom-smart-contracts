module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000
    },
  },
  compilers: {
    solc: {
      version: ">=0.6.0 <0.9.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    }
  }


};
