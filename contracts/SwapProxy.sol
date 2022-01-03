// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";

contract SwapProxy {
    mapping(address => mapping(address => uint256)) swapedTokens_;

    function getSwapedErc20(address depositer, address erc20addr) public view returns(uint256) {
        return swapedTokens_[depositer][erc20addr];
    }

    // 取回msg.sender已经兑换到的Token, 由已经存入了ETH的账号发起
    // @param erc20token 已经兑换到的ERC20 token
    // @param to         收货地址
    function claimErc20(address erc20token, address to) public {
        uint256 swapedToken = swapedTokens_[msg.sender][erc20token];
        require(swapedToken > 0, "no erc20 token swaped");

        IERC20 token = IERC20(erc20token);
        uint256 total = token.balanceOf(address(this));
        require(total >= swapedToken, "no enough erc20 token left");

        swapedTokens_[msg.sender][erc20token] = 0;

        token.transfer(to, swapedToken);
    }

    // 使用ETH从指定的路径兑换Token
    // 所以swappaths[0] 是WETH的合约地址, swappaths[len - 1] 是目标Token合约地址
    //
    // @param router        Swap的router地址
    // @param depositer     已经存入ETH的账号
    // @param amountMinOut  最小可接受的输出
    // @param swappaths     兑换路径
    function swap(address router, address depositer, uint256 amountMinOut, address[] memory swappaths) public payable {

        uint256 len = swappaths.length;
        uint256[] memory swapedAmounts = new uint256[](len);
        address erc20TokenAddr = swappaths[len - 1];

        IPancakeRouter02 pancake = IPancakeRouter02(router);
        swapedAmounts = pancake.swapExactETHForTokens{value: msg.value}(amountMinOut, swappaths, address(this), block.timestamp + 30 minutes);

        swapedTokens_[depositer][erc20TokenAddr] += swapedAmounts[len - 1];
    }
}