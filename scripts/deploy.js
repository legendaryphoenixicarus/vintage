// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require('fs');

async function main() {
  const BEP20Token = await hre.ethers.getContractFactory("BEP20Token");
  const bEP20Token = await BEP20Token.deploy();
  await bEP20Token.deployed();
  console.log("BEP20Mine deployed to:", bEP20Token.address);
  
  // export const busdaddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56"

  const VintageToken = await hre.ethers.getContractFactory("VintageToken");
  const vintageToken = await VintageToken.deploy(bEP20Token.address);
  await vintageToken.deployed();
  console.log("VintageToken deployed to:", vintageToken.address);

  let config = `
  export const vintagetokenaddress = "${vintageToken.address}"
  export const busdaddress = "${bEP20Token.address}"
  `
  let data = JSON.stringify(config);
  fs.writeFileSync('config.js', JSON.parse(data));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
