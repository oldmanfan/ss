# SwapService使用指南


这个服务是用来代理购买流动性池中的代币.  

一共有两个合约**SwapService.sol**和**SwapProxy**:  

其中:

**SwapService**是服务入口, 用于管理ETH资产, **SwapProxy**是代理合约, 用于兑换和管理ERC20资产.


## 操作说明

### I 部署合约
#### 使用scripts/deploy.js脚本部署
1. 如果使用`scripts/deploy.js`脚本部署的话, 可以**修改**一下里面的**PancakeV2Router**配置,
```js
const SwapProxy = await hre.ethers.getContractFactory("SwapProxy");
  const proxy = await SwapProxy.deploy();

  await proxy.deployed();

  console.log("SwapProxy deployed to:", proxy.address);


  const SwapService = await hre.ethers.getContractFactory("SwapService");

  const PancakeV2Router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'; // 修改这一行地址为Uniswap V2地址

  const service = await SwapService.deploy(PancakeV2Router, proxy.address);

  await service.deployed();

  console.log("SWapService deployed to : ", service.address);
```

2. 修改hardhat.config.js中账号信息
```js
 mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: ['0x私钥'],
      gasPrice: 120 * 1000000000,
      chainId: 1,
    },
```

3. 使用以下命令进行部署
`npx hardhat run scritps/deploy.js --network mainnet`

#### 使用Remix部署
1. 先部署`SwapProxy`合约, 获得地址PROXY.
2. 部署`SwapService`合约. 这个合约部署时需要使用到两个参数:  
* `router`  填上UniSwapV2的地址;  
* `proxy`   填上第一步获得的PROXY地址.

### II 转入ETH

1. 转入ETH:   直接向SwapService合约地址转账.

### III 配置抢购参数
为防止有人恶意攻击, 需要使用**Owner**权限的账号(即部署合约的账号), 配置一次抢购的参数.
```c++
function setSwapParams(address depositer, uint256 stepEth, uint256 minOut, address[] memory swappaths) public onlyOwner {
        swapSettings_[depositer] = SwapSetting(stepEth, minOut, swappaths);
}
```

其中: 
* depositer     兑换的账号, 已经存入了ETH的账号
* stepEth       每次尝试兑换使用的ETH数量, 比如已经存入了100ETH, 为了避免一次兑换把价格拉的太高, 可以每次尝试使用10ETH来兑换.
* minOut        每一次兑换最小可接受的获得ERC20代币数量, 用来控制价格
* swappaths     兑换路径, WETH -> ERC20代币的兑换路径

### IV 执行抢购
在已经转入了ETH, 并配置了抢购参数的情况下, 可以用**任意多个账号**来调用下面的方法, 只要有一个账号的交易成功, 其它的交易就会自然失败.  
`function swapETH(address depositer) public`  

这个方法只接受一个参数: `depositer`就是**配置**章节中, 已经配置的用于抢购的账号.

### V 提取剩余的ETH和/或兑换到的ERC20代币

1. 提取剩下的ETH
* 调用`SwapService`的`getLeftEth`方法, 看是否有剩下的ETH.
* 如果有剩下的ETH, 则使用`depositer`账号, 调用`SwapService`的`claimEth`方法, 取回ETH.

2. 提取兑换到的ERC20
* 调用`SwapProxy`的`getSwapedErc20`方法, 查看可以提取的ERC20的代币数量.
* 使用`depositer`账号, 调用`SwapProxy`的`claimErc20`方法, 取回ERC20代币.

