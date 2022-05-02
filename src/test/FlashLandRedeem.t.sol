// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "../FlashLandRedeem.sol";
import { ILendingPoolAddressesProvider } from "protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import { IWETH } from "looksrare/IWETH.sol";
import { IERC721 } from "looksrare/IERC721.sol";
import { SomeAccount } from "./Mocks/Mocks.sol";

import { OrderTypes } from "looksrare/OrderTypes.sol";

interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
}

contract FlashRedeemLandTest is DSTest {

    address private WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ILendingPoolAddressesProvider private AAVE_LP_PROVIDER = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address private LAND_ADDRESS = 0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258;

    IWETH weth = IWETH(WETH_ADDR);

    address private MAYC_NFT_ADDR = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    IERC721 MAYC_NFT = IERC721(MAYC_NFT_ADDR);

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    FlashLandRedeem flashLandRedeem;

    function setUp() public {
        flashLandRedeem = new FlashLandRedeem(AAVE_LP_PROVIDER, LAND_ADDRESS);
    }

    function testNFTWithdrawal() public {
        // send MAYC NFT to contract
        address flashLandRedeemContractAddr = address(flashLandRedeem);
        address MAYC_HOLDER_ADDR = 0xbc91d03B996C10e2DaDd802e7BfEc889640D00c0;

        assertEq(MAYC_NFT.balanceOf(flashLandRedeemContractAddr), 0);
        cheats.startPrank(MAYC_HOLDER_ADDR);

        MAYC_NFT.safeTransferFrom(MAYC_HOLDER_ADDR, flashLandRedeemContractAddr, 8786);
        assertEq(MAYC_NFT.balanceOf(flashLandRedeemContractAddr), 1);
        cheats.stopPrank();

        // verify we can withdraw the NFT
        flashLandRedeem.withdrawNFT(msg.sender, 8786, MAYC_NFT_ADDR);
        assertEq(MAYC_NFT.balanceOf(msg.sender), 1);
        assertEq(MAYC_NFT.balanceOf(flashLandRedeemContractAddr), 0);
    }

    function testWithdrawalSuccess() public {
        SomeAccount someAccount = new SomeAccount();
        address flashLandRedeemContractAddr = address(flashLandRedeem);
        uint256 amt = 1 ether;
        payable(flashLandRedeemContractAddr).transfer(amt);
        address to = address(someAccount);
        assertTrue(flashLandRedeemContractAddr.balance == amt);

        flashLandRedeem.withdrawETH(to, amt);
        assertEq(to.balance, amt);
        assertEq(flashLandRedeemContractAddr.balance, 0);
    }

    function testFlashLandRedeem() public {
        uint256 amountToFlashLoan = 39.4 ether;
        uint256 amountToSendForRepay = 3145460000000000000; // 39.4 + (39.4 * 9bps) - (38 - 38 * .045) blockNo: 14676636

        address flashLandRedeemContractAddr = address(flashLandRedeem);
        console.log("flashLandRedeemContractAddr: ", flashLandRedeemContractAddr);
        console.log("msg sender address", address(msg.sender));

        OrderTypes.MakerOrder memory makerAsk = OrderTypes.MakerOrder({
            isOrderAsk: true,
            signer: 0xbc91d03B996C10e2DaDd802e7BfEc889640D00c0,
            collection: 0x60E4d786628Fea6478F785A6d7e704777c86a7c6,
            price: 39400000000000000000,
            tokenId: 8786,
            amount: 1,
            strategy: 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 23,
            startTime: 1651193203,
            endTime: 1651976855,
            minPercentageToAsk: 8500,
            params: "",
            v: 28,
            r: 0xa11d793ff3981a78af911b177352b3c8368f12ea942b956b09d0979ac3a33d17,
            s: 0x00be19dff04cb6e67357fe0b813b4f601bfb8191be0f69762cc9157294ff5036
        });

        OrderTypes.TakerOrder memory takerBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: flashLandRedeemContractAddr,
            price: 39400000000000000000,
            tokenId: 8786,
            minPercentageToAsk: 8500,
            params: ""
        });

        OrderTypes.MakerOrder memory makerBid = OrderTypes.MakerOrder({
            isOrderAsk: false,
            signer: 0xCB0b877eC8fe90a75315E88648f49e3133dc6aFB,
            collection: 0x60E4d786628Fea6478F785A6d7e704777c86a7c6,
            price: 38000000000000000000,
            tokenId: 0,
            amount: 1,
            strategy: 0x86F909F70813CdB1Bc733f4D97Dc6b03B8e7E8F3,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 11,
            startTime: 1651198531,
            endTime: 1651284926,
            minPercentageToAsk: 8500,
            params: "",
            v: 28,
            r: 0x3ba2232a8be12480395116f1bc0f19c1b6ead0091b1db1da6b0de82db5538394,
            s: 0x78a72e6708ec12cb2784d63a6dfd50d85622a376c30f96a41f9227ca1c1de58b
        });

        OrderTypes.TakerOrder memory takerAsk = OrderTypes.TakerOrder({
            isOrderAsk: true,
            taker: flashLandRedeemContractAddr,
            price: 38000000000000000000,
            tokenId: 8786,
            minPercentageToAsk: 8500,
            params: ""
        });

        bytes memory params = abi.encode(makerAsk, takerBid, makerBid, takerAsk);

        flashLandRedeem.flashLandRedeem{value: amountToSendForRepay}(WETH_ADDR, amountToFlashLoan, params);

        uint256 balanceAfter = msg.sender.balance;
        console.log("balanceAfter", balanceAfter);
    }
}
