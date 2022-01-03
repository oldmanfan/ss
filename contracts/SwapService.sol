// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";
import "./SwapProxy.sol";
import "hardhat/console.sol";

contract SwapService {
    address owner_;

    address routerAddress_;

    address proxyAddress_;

    // 存入ETH的数量, 账号 => ETH数量
    mapping(address => uint256) depositEth_;

    // 已经兑换到的Token记录:  账号 => Token合约地址 => 数量
    mapping(address => mapping(address => uint256)) swapedTokens_;

    modifier onlyOwner() {
        require(msg.sender == owner_, "only owner");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only EOA");
        _;
    }

    constructor(address router, address proxy) {
        owner_ = msg.sender;
        routerAddress_ = router;
        proxyAddress_ = proxy;
    }

    receive () external payable {
        depositEth_[msg.sender] += msg.value;
    }

    fallback () external payable {
        revert("not support anonmous calling");
    }

    function setProxyAddress(address proxy) public {
        proxyAddress_ = proxy;
    }

    function setRouterAddress(address router) public onlyOwner {
        routerAddress_ = router;
    }

    function getSwapedToken(address depositer, address erc20Token) public view returns(uint256) {
        return swapedTokens_[depositer][erc20Token];
    }

    // 取回msg.sender已经兑换到的Token
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

    // 取回存入的ETH
    // @param to   收货地址
    function claimEth(address payable to) public {
        uint256 depositedEth = depositEth_[msg.sender];
        require(depositedEth > 0, "no ETH left for msg.sender");

        uint256 ethbalance = address(this).balance;
        require(ethbalance >= depositedEth, "no enough ETH left in contract");

        to.transfer(depositedEth);
    }

    // 使用ETH从指定的路径兑换Token
    // 所以swappaths[0] 是WETH的合约地址, swappaths[len - 1] 是目标Token合约地址
    //
    // @param depositer     已经存入ETH的账号
    // @param ethamount     准备兑换的ETH数量
    // @param amountMinOut  最小可接受的输出
    // @param swappaths     兑换路径
    function swapETH(address depositer, uint256 minoutPerLoop, address[] memory swappaths) public {
        uint256 depositEth = depositEth_[depositer];

        // uint256 minOut = 4e18; // 1ETH : 4TOKEN
        uint256 perLoop = 1e16;
        uint i = 1;
        while (depositEth >= perLoop) { // 每次兑换1个ETH

           (bool success, ) =
            proxyAddress_.call{value: perLoop}(
                abi.encodeWithSignature(
                    "swap(address,uint256,address[])",
                    routerAddress_,
                    minoutPerLoop * i,
                    swappaths
                )
            );
            if (!success) break;

            depositEth -= perLoop;

            i++;
        }
        depositEth_[depositer] = depositEth;
    }
}