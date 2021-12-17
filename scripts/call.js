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
  // 0x1cbd3b2770909d4e10f157cabc84c7264073c9ec  0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd
  // 0x2546bcd3c84621e976d8185a91a922ae77ecec30  0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0
  const SS = await hre.ethers.getContractFactory('SS');
  const ss = await SS.attach('0xA7c5a338c7858B601B777fd389A0B93fA55bD92b');

  // const receipt = await ss.swap();

  // const receipt = await ss.claim('0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56', '0xCa5752D162d6464aAf029AbACea045F07Ae4862e');

  const receipt = await ss.drainbnb('0xCa5752D162d6464aAf029AbACea045F07Ae4862e');

  console.log('receipt: ', JSON.stringify(receipt));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
