// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { FlashLoanReceiverBase } from "protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import { ILendingPool } from "protocol-v2/contracts/interfaces/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import { IERC20 } from "protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import { ILooksRareExchange } from "looksrare/ILooksRareExchange.sol";
import { OrderTypes } from "looksrare/OrderTypes.sol";
import { IWETH } from "looksrare/IWETH.sol";
import { IERC721 } from "looksrare/IERC721.sol";
import { Ownable } from "looksrare/Ownable.sol";

import "forge-std/console.sol";

interface ILandAirdrop {
    function nftOwnerClaimLand(uint256[] calldata alphaTokenIds, uint256[] calldata betaTokenIds) external;
    function alphaClaimed(uint256 tokenId) external view returns (bool);
    function betaClaimed(uint256 tokenId) external view returns (bool);
}

contract FlashLandRedeem is FlashLoanReceiverBase, Ownable {

    // ============ Private constants ============
    address private LR_EXCH_ADDR = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address private LR_TFER_MANAGER_ADDR = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    address private WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private BAYC_NFT_ADDR = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address private MAYC_NFT_ADDR = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;

    address private landAddress;

    uint256[] private alphaTokenIds;
    uint256[] private betaTokenIds;

    constructor(ILendingPoolAddressesProvider _addressProvider,
                address _landAddress) FlashLoanReceiverBase(_addressProvider) public {
        landAddress = _landAddress;
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    // Make contract payable to receive funds
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawETH(address to, uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        require(to != address(0));
        payable(to).transfer(amount);
        return true;
    }

    function withdrawNFT(address to, uint256 tokenId, address collectionAddress) public onlyOwner returns(bool) {
        IERC721 nft = IERC721(collectionAddress);
        nft.setApprovalForAll(to, true);
        nft.safeTransferFrom(address(this), to, tokenId, "");
        return true;
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
    external
    override
    returns (bool)
    {
        address asset  = assets[0];
        uint256 amount = amounts[0];
        uint256 amountOwing = amount.add(premiums[0]);

        IERC20 assetToken = IERC20(asset);
        safeApprove(asset, LR_EXCH_ADDR, amount);

        ILooksRareExchange looksRareExchange = ILooksRareExchange(LR_EXCH_ADDR);
        (OrderTypes.MakerOrder memory makerAsk, OrderTypes.TakerOrder memory takerBid,
         OrderTypes.MakerOrder memory makerBid, OrderTypes.TakerOrder memory takerAsk) = abi.decode(params, (OrderTypes.MakerOrder, OrderTypes.TakerOrder,
                                                                                                             OrderTypes.MakerOrder, OrderTypes.TakerOrder));
        looksRareExchange.matchAskWithTakerBid(takerBid, makerAsk);

        /*
        ILandAirdrop landAirdrop = ILandAirdrop(landAddress);
        if (makerAsk.collection == BAYC_NFT_ADDR) {
            alphaTokenIds.push(makerAsk.tokenId);
            bool alphaClaimed = landAirdrop.alphaClaimed(makerAsk.tokenId);
            require(
                alphaClaimed == false,
                "Land already claimed."
            );
        } else {
            betaTokenIds.push(makerAsk.tokenId);
            bool betaClaimed = landAirdrop.betaClaimed(makerAsk.tokenId);
            require(
                betaClaimed == false,
                "Land already claimed."
            );
        }
        landAirdrop.nftOwnerClaimLand(alphaTokenIds, betaTokenIds);
        */

        IERC721 nft = IERC721(makerBid.collection);
        nft.setApprovalForAll(LR_TFER_MANAGER_ADDR, true);
        looksRareExchange.matchBidWithTakerAsk(takerAsk, makerBid);

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // wrap ETH -> WETH
        IWETH weth = IWETH(WETH_ADDR);
        uint256 amountToWrap = amountOwing - weth.balanceOf(address(this));
        weth.deposit{value: amountToWrap}();

        // Approve the LendingPool contract allowance to *pull* the owed amount
        safeApprove(asset, address(LENDING_POOL), amountOwing);
        return true;
    }

    function flashLandRedeem(address debtAssetAddr, uint256 amount, bytes memory params) payable public {

        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = debtAssetAddr;

        uint256[] memory amounts = new uint256[](1);
        // uint256 amount = 1 ether;
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")); // IERC721Receiver.onERC721Received.selector
    }
}
