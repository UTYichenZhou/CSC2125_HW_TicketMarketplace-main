// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import {SampleCoin} from "./SampleCoin.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)

    struct Event {
        uint128 next_ticket_to_sell;
        uint128 max_tickets;
        uint256 price_per_ticket;
        uint256 price_per_ticket_ERC20;
    }

    address public owner;
    SampleCoin internal erc20_coin_address;
    TicketNFT internal ticket_nft;
    uint128 internal newEventId;

    Event[] internal events_list;

    constructor (address coinAddress) {
        owner = msg.sender;
        erc20_coin_address = SampleCoin(coinAddress);
        string memory ticket_nft_uri = "";
        ticket_nft = new TicketNFT(ticket_nft_uri);
        newEventId = 0;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function nftContract() external view returns (address) {
        return address(ticket_nft);
    }

    function ERC20Address() external view returns (address) {
        return address(erc20_coin_address);
    }

    function currentEventId() external view returns (uint256) {
        return newEventId;
    }

    function setERC20Address(address newERC20Address) external override {
        require(msg.sender == owner, "Unauthorized access");
        erc20_coin_address = SampleCoin(newERC20Address);
        emit ERC20AddressUpdate(newERC20Address);
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override {
        require(msg.sender == owner, "Unauthorized access");
        events_list.push(Event({next_ticket_to_sell: 0, max_tickets: maxTickets, price_per_ticket: pricePerTicket, 
                                price_per_ticket_ERC20: pricePerTicketERC20}));
        emit EventCreated(newEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        newEventId++;
    }

    function events(uint128 index) external view returns (uint128 nextTicketToSell, uint128 maxTickets, uint256 pricePerTicket, 
                                                     uint256 pricePerTicketERC20) {
        require(index < newEventId);
        return (events_list[index].next_ticket_to_sell, events_list[index].max_tickets, events_list[index].price_per_ticket,
                events_list[index].price_per_ticket_ERC20);
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override {
        require(msg.sender == owner, "Unauthorized access");
        require(eventId < newEventId);
        require(newMaxTickets >= events_list[eventId].max_tickets, "The new number of max tickets is too small!");
        events_list[eventId].max_tickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override {
        require(msg.sender == owner, "Unauthorized access");
        require(eventId < newEventId);
        events_list[eventId].price_per_ticket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external {
        require(msg.sender == owner, "Unauthorized access");
        require(eventId < newEventId);
        events_list[eventId].price_per_ticket_ERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override {
        require(eventId < newEventId);
        require(ticketCount == 0 || ticketCount <= type(uint256).max/events_list[eventId].price_per_ticket,
                "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount <= events_list[eventId].max_tickets - events_list[eventId].next_ticket_to_sell,
                "We don't have that many tickets left to sell!");
        require(ticketCount*events_list[eventId].price_per_ticket <= msg.value,
                "Not enough funds supplied to buy the specified number of tickets.");
        uint256 nft_id = (uint256(eventId) << 128) + events_list[eventId].next_ticket_to_sell;
        for(uint128 i = 0; i < ticketCount; i++){
            ticket_nft.mintFromMarketPlace(msg.sender, nft_id);
            nft_id++;
            events_list[eventId].next_ticket_to_sell++;
        }
        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        require(eventId < newEventId);
        require(ticketCount > 0, "Not buying any tickets");
        require(ticketCount <= type(uint256).max/events_list[eventId].price_per_ticket_ERC20,
                "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount <= events_list[eventId].max_tickets - events_list[eventId].next_ticket_to_sell,
                "We don't have that many tickets left to sell!");
        require(ticketCount*events_list[eventId].price_per_ticket_ERC20 <= erc20_coin_address.balanceOf(msg.sender),
                "Not enough funds supplied to buy the specified number of tickets.");
        uint256 nft_id = (uint256(eventId) << 128) + events_list[eventId].next_ticket_to_sell;
        for(uint128 i = 0; i < ticketCount; i++){
            ticket_nft.mintFromMarketPlace(msg.sender, nft_id);
            nft_id++;
            events_list[eventId].next_ticket_to_sell++;
        }
        uint256 payment = ticketCount*events_list[eventId].price_per_ticket_ERC20;
        erc20_coin_address.transferFrom(msg.sender, address(this), payment);
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }
}