// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasAuction {
    struct Bid {
        address bidder;
        uint256 bidAmount; // Monto ofertado en wei
        uint256 gasPrice;  // Precio del gas ofertado en gwei
    }

    Bid[] public bids; // Lista de ofertas
    uint256 public auctionEndTime; // Tiempo de finalización de la subasta
    address public owner;

    event NewBid(address indexed bidder, uint256 bidAmount, uint256 gasPrice);
    event AuctionEnded(address winner, uint256 highestBid, uint256 winningGasPrice);

    constructor(uint256 _durationMinutes) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + (_durationMinutes * 1 minutes);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        _;
    }

    function placeBid(uint256 gasPrice) public payable auctionActive {
        require(msg.value > 0, "Bid amount must be greater than zero");
        require(gasPrice > 0, "Gas price must be greater than zero");

        bids.push(Bid({bidder: msg.sender, bidAmount: msg.value, gasPrice: gasPrice}));

        emit NewBid(msg.sender, msg.value, gasPrice);
    }

    function getHighestBid() public view returns (address, uint256, uint256) {
        require(bids.length > 0, "No bids placed yet");

        Bid memory highestBid = bids[0];
        for (uint256 i = 1; i < bids.length; i++) {
            if (bids[i].gasPrice > highestBid.gasPrice || 
                (bids[i].gasPrice == highestBid.gasPrice && bids[i].bidAmount > highestBid.bidAmount)) {
                highestBid = bids[i];
            }
        }

        return (highestBid.bidder, highestBid.bidAmount, highestBid.gasPrice);
    }

    function endAuction() public onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction is still active");

        (address winner, uint256 highestBid, uint256 winningGasPrice) = getHighestBid();
        emit AuctionEnded(winner, highestBid, winningGasPrice);

        // Transfer funds to owner
        payable(owner).transfer(address(this).balance);
    }

    function getBids() public view returns (Bid[] memory) {
        return bids;
    }
}
