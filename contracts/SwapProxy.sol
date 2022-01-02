// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";

contract SwapProxy {
    function swapETH(address router, uint256 amountMinOut, address[] memory swappaths) public payable {
        IPancakeRouter02 pancake = IPancakeRouter02(router);
        pancake.swapExactETHForTokens{value: msg.value}(amountMinOut, swappaths, address(this), block.timestamp + 30 minutes);
    }
}