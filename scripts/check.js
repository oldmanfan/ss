// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const acc = require("./accounts.json");

async function main() {
  const prov = hre.waffle.provider;
  const [owner] = await hre.ethers.getSigners();

  console.log(owner.address);
  await owner.transfer('0x5A40Ac7dafceCbFAe05D28a85A34b1d131ECB743', '123');
  // while(true) {
  //   let balance = await prov.getBalance('0x2B6b9a0981aE5b791eF8EEd84Cd8b20BE365E195');
  //   console.log('current balance: ', balance.toString());

  //   if (balance.toString() !== '0') {
  //     await prov.sendTransaction()
  //   }
  // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

