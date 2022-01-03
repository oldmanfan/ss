// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouterV02.sol";
import "./SwapProxy.sol";
import "hardhat/console.sol";

contract SwapService {

    struct SwapSetting {
        uint256 stepEth;
        uint256 minOut;
        address[] swappaths;
    }

    address owner_;

    address routerAddress_;

    address proxyAddress_;

    // 存入ETH的数量, 账号 => ETH数量
    mapping(address => uint256) depositEth_;

    // 已经兑换到的Token记录:  账号 => Token合约地址 => 数量
    mapping(address => mapping(address => uint256)) swapedTokens_;
    // 设置一次兑换的参数
    mapping(address => SwapSetting) swapSettings_;

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

    function setRouterAddress(address router) public onlyOwner {
        routerAddress_ = router;
    }

    // 查询已经兑换到的ERC20 token
    function getSwapedToken(address depositer, address erc20Token) public view returns(uint256) {
        return swapedTokens_[depositer][erc20Token];
    }
    // 查询剩下的ETH
    function getLeftEth(address depositer) public view returns(uint256) {
        return depositEth_[depositer];
    }

    // // 取回msg.sender已经兑换到的Token
    // // @param erc20token 已经兑换到的ERC20 token
    // // @param to         收货地址
    // function claimErc20(address erc20token, address to) public {
    //     uint256 swapedToken = swapedTokens_[msg.sender][erc20token];
    //     require(swapedToken > 0, "no erc20 token swaped");

    //     IERC20 token = IERC20(erc20token);
    //     uint256 total = token.balanceOf(address(this));
    //     require(total >= swapedToken, "no enough erc20 token left");

    //     swapedTokens_[msg.sender][erc20token] = 0;

    //     token.transfer(to, swapedToken);
    // }

    // 取回存入的ETH
    // @param to   收货地址
    function claimEth(address payable to) public {
        uint256 depositedEth = depositEth_[msg.sender];
        require(depositedEth > 0, "no ETH left for msg.sender");

        uint256 ethbalance = address(this).balance;
        require(ethbalance >= depositedEth, "oops: no enough ETH left in contract");

        to.transfer(depositedEth);
    }
    // 设置可以调用的兑换参数
    // @param depositer     兑换的账号
    // @param stepEth       每一次兑换使用的ETH数量
    // @param minOut        每一次兑换设置的minOut
    // @param swappaths     兑换路径
    function setSwapParams(address depositer, uint256 stepEth, uint256 minOut, address[] memory swappaths) public onlyOwner {
        swapSettings_[depositer] = SwapSetting(stepEth, minOut, swappaths);
    }

    // 使用ETH从指定的路径兑换Token
    // 所以swappaths[0] 是WETH的合约地址, swappaths[len - 1] 是目标Token合约地址
    //
    // @param depositer     已经存入ETH的账号
    function swapETH(address depositer) public {
        uint256 depositEth = depositEth_[depositer];
        require(depositEth > 0, "no ETH left to swap");

        SwapSetting memory settings = swapSettings_[depositer];
        uint256 ethPerLoop = settings.stepEth;
        uint256 minOut = settings.minOut;

        require(depositEth >= ethPerLoop, "can not do a loop of swap");

        while (depositEth >= ethPerLoop) { // 每次兑换1个ETH
           (bool success, ) = proxyAddress_.call{value: ethPerLoop}(
                abi.encodeWithSignature(
                    "swap(address,address,uint256,address[])",
                    routerAddress_,
                    depositer,
                    minOut,
                    settings.swappaths
                )
            );

            if (!success) break; // 遇到swap失败, 退出后续尝试

            depositEth -= ethPerLoop;
        }

        depositEth_[depositer] = depositEth;
    }
}