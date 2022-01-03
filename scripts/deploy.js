// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const SwapProxy = await hre.ethers.getContractFactory("SwapProxy");
  const proxy = await SwapProxy.deploy();

  await proxy.deployed();

  console.log("SwapProxy deployed to:", proxy.address);


  const SwapService = await hre.ethers.getContractFactory("SwapService");

  const PancakeV2Router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';

  const service = await SwapService.deploy(PancakeV2Router, proxy.address);

  await service.deployed();

  console.log("SWapService deployed to : ", service.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
