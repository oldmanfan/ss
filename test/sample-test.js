const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {

    const signers = await ethers.getSigners();

    const SwapProxy = await ethers.getContractFactory("SwapProxy");
    const proxy = await SwapProxy.deploy();

    await proxy.deployed();

    console.log("SwapProxy deployed to:", proxy.address);


    const SwapService = await ethers.getContractFactory("SwapService");
    const service = await SwapService.deploy('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', proxy.address);

    await service.deployed();


    console.log("SWapService deployed to : ", service.address);
    // let p = signers[1];
    // await p.transfer(service.address, "100000000000000000");
    await signers[1].sendTransaction({
      to: service.address,
      value: ethers.utils.parseEther("2") // 1 ether
    })

    await service.setSwapParams(signers[1].address, ethers.utils.parseEther("1"), ethers.utils.parseEther("20"), []);

    await service.swapETH(signers[1].address);

    const out = await proxy.getSwapedErc20(signers[1].address, "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
    console.log('out: ', out.toString());
  });
});
