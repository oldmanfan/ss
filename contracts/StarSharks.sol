// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";

contract SS {
    address owner_;

    address routerAddress_;

    mapping(bytes32 => bool) approvedTokens_;

    mapping(bytes32 => bool) txLabels_;

    modifier onlyOwner() {
        require(msg.sender == owner_, "only owner");
        _;
    }

    constructor() {
        owner_ = msg.sender;
        routerAddress_ = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // pancakge router v02
    }

    receive () external payable {
        // nop
    }

    function setRouterAddress(address router) public onlyOwner {
        routerAddress_ = router;
    }

    function claim(address erc20token, address to) public onlyOwner {
        IERC20 token = IERC20(erc20token);
        uint256 total = token.balanceOf(address(this));
        token.transfer(to, total);
    }

    function drainbnb(address payable to) public onlyOwner {
        uint256 bnbleft = address(this).balance;
        to.transfer(bnbleft);
    }

    function swapETH(bytes32 txhash, uint256 bnbamount, uint256 amountMinOut, address[] memory swappaths) public {
        require(!txLabels_[txhash], "have finished");

        IPancakeRouter02 pancake = IPancakeRouter02(routerAddress_);
        pancake.swapExactETHForTokens{value: bnbamount}(amountMinOut, swappaths, address(this), block.timestamp + 30 minutes);

        txLabels_[txhash] = true;
    }

    // txhash 一次目标的唯一标志
    // fromToken 兑换使用的Token地址
    // amountIn  兑换使用的token数量
    // amountMinOut 兑换预计的最小产出
    // swappaths    兑换路径
    function swaperc20(bytes32 txhash, address fromToken, uint256 amountIn, uint256 amountMinOut, address[] memory swappaths) public {
        require(!txLabels_[txhash], "have finished");

        if (!approvedTokens_[txhash]) {
            IERC20 token = IERC20(fromToken);
            token.approve(routerAddress_, amountIn);
            approvedTokens_[txhash] = true;
        }


        IPancakeRouter02 pancake = IPancakeRouter02(routerAddress_);

        pancake.swapExactTokensForTokens(amountIn, amountMinOut, swappaths, address(this), block.timestamp + 30 minutes);

        txLabels_[txhash] = true;
    }
}