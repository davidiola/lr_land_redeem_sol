// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { OrderTypes } from "./OrderTypes.sol";

interface ILooksRareExchange {
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
    external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
    external;
}