// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    uint256 public tokenCount;
    uint256 public listingFee = 0.01 ether;

    struct NFT {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }

    mapping(uint256 => NFT) public nfts;

    event NFTListed(uint256 indexed tokenId, uint256 price, address seller);
    event NFTSold(uint256 indexed tokenId, address buyer);

    constructor() ERC721("NFTMarketplace", "NFTM") {}

    function mintNFT(string memory tokenURI, uint256 price, uint256 royalty) public payable {
        require(royalty <= 100, "Royalty must be <= 100%");
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingFee, "Must pay listing fee");

        tokenCount++;
        uint256 tokenId = tokenCount;

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        royalties[tokenId] = royalty;

        nfts[tokenId] = NFT(tokenId, payable(msg.sender), payable(address(0)), price, true);

        emit NFTListed(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) public payable {
        NFT storage nft = nfts[tokenId];
        require(nft.listed, "NFT is not for sale");
        require(msg.value == nft.price, "Incorrect price");

        uint256 royaltyAmount = (msg.value * royalties[tokenId]) / 100;
        nft.seller.transfer(msg.value - royaltyAmount);
        nft.owner = payable(msg.sender);
        nft.listed = false;

        _transfer(nft.seller, msg.sender, tokenId);

        emit NFTSold(tokenId, msg.sender);
    }



  return nftList.filter(nft => nft.listed); // Show only listed NFTs
}

    function withdrawListingFee() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    struct Auction {
    uint256 tokenId;
    address payable seller;
    uint256 startingPrice;
    uint256 highestBid;
    address payable highestBidder;
    uint256 endTime;
    bool ended;
}

    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(uint256 indexed tokenId, uint256 startingPrice, uint256 endTime);
    event NewBid(uint256 indexed tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 winningBid);

    function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public {
        require(msg.sender == nfts[tokenId].owner, "Only the owner can create an auction");
        require(nfts[tokenId].listed == false, "NFT must not be listed for sale");
        require(duration > 0, "Duration must be greater than zero");

        auctions[tokenId] = Auction(
            tokenId,
            payable(msg.sender),
            startingPrice,
            0,
            payable(address(0)),
            block.timestamp + duration,
            false
        );

        emit AuctionCreated(tokenId, startingPrice, block.timestamp + duration);
    }

    function placeBid(uint256 tokenId) public payable {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid");

        if (auction.highestBid > 0) {
            // Refund the previous highest bidder
            auction.highestBidder.transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit NewBid(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) public {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp >= auction.endTime, "Auction is still ongoing");
        require(!auction.ended, "Auction has already ended");

        auction.ended = true;

        if (auction.highestBid > 0) {
            auction.seller.transfer(auction.highestBid);
            nfts[tokenId].owner = auction.highestBidder;
            nfts[tokenId].listed = false;

            _transfer(auction.seller, auction.highestBidder, tokenId);
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function bulkListNFTs(uint256[] memory tokenIds, uint256[] memory prices) public {
        require(tokenIds.length == prices.length, "Token IDs and prices must match");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];

            require(msg.sender == nfts[tokenId].owner, "Only the owner can list this NFT");
            require(price > 0, "Price must be greater than zero");

            nfts[tokenId].price = price;
            nfts[tokenId].listed = true;

            emit NFTListed(tokenId, price, msg.sender);
        }
    }
    mapping(uint256 => address[]) public ownershipHistory;

    function transferNFT(address to, uint256 tokenId) internal {
        require(_exists(tokenId), "Token does not exist");

        ownershipHistory[tokenId].push(to);
        _transfer(msg.sender, to, tokenId);
    }

    function getOwnershipHistory(uint256 tokenId) public view returns (address[] memory) {
        return ownershipHistory[tokenId];
    }

    mapping(uint256 => bool) public featuredNFTs;

    function setFeaturedNFT(uint256 tokenId, bool isFeatured) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        featuredNFTs[tokenId] = isFeatured;
    }

    function getFeaturedNFTs() public view returns (uint256[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (featuredNFTs[i]) count++;
        }

        uint256[] memory result = new uint256[](count);
        uint256 index;

        for (uint256 i = 1; i <= tokenCount; i++) {
            if (featuredNFTs[i]) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

}

async function fetchNFTs(contract) {
        const totalSupply = await contract.tokenCount();
        let nftList = [];

        for (let i = 1; i <= totalSupply; i++) {
        const nft = await contract.nfts(i);
        nftList.push({
            tokenId: i,
            seller: nft.seller,
            owner: nft.owner,
            price: ethers.utils.formatEther(nft.price),
            listed: nft.listed,
        });
    }
}