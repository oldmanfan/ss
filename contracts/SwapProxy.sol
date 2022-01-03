// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";
import "./SwapProxy.sol";
import "hardhat/console.sol";

contract SwapProxy {
    // 使用ETH从指定的路径兑换Token
    // 所以swappaths[0] 是WETH的合约地址, swappaths[len - 1] 是目标Token合约地址
    //
    // @param depositer     已经存入ETH的账号
    // @param ethamount     准备兑换的ETH数量
    // @param amountMinOut  最小可接受的输出
    // @param swappaths     兑换路径
    function swap(address router, uint256 amountMinOut, address[] memory swappaths) public payable {

        IPancakeRouter02 pancake = IPancakeRouter02(router);
        pancake.swapExactETHForTokens{value: msg.value}(amountMinOut, swappaths, address(this), block.timestamp + 30 minutes);
    }
}