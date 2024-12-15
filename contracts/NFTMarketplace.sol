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

    function withdrawListingFee() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}