require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks : {
    sepolia : {
      url : "https://eth-sepolia.g.alchemy.com/v2/a-5arYmOpY-hEBb7CIAIS8f0e9Gct7xi",
      accounts : ["6fe879e3559ad4da0f3fb6cad23ca7ba206d52a99d3b976b7f8346a7e8661d96"]
    },
    localhost : {
      url: "http://127.0.0.1:8545/",
      chainId : 31337
    }
  }
};
