/* hardhat.config.js */
require("@nomiclabs/hardhat-waffle")
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");

const fs = require('fs')
const privateKey = fs.readFileSync(".secret").toString().trim() || "01234567890123456789";
const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";
const bscscanApiKey = fs.readFileSync(".apikey").toString().trim() || "";

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${infuraId}`,
      accounts: [privateKey],
    },

    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      // chainId: 97,
      // gasPrice: 20000000000,
      // accounts: {mnemonic: mnemonic}
      accounts: [privateKey],
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [privateKey],
    }
  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: bscscanApiKey
  },

  solidity: {
    // version: "0.7.5",
    compilers: [
      {
        version: "0.7.5"
      },
      {
        version: "0.8.0"
      },
      {
        version: "0.8.3"
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}