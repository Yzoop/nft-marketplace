const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  it("Should mint and trade NFTs", async function () {
    const [owner, buyer] = await ethers.getSigners();

    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    const nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.deployed();

    const listingFee = await nftMarketplace.listingFee();
    const price = ethers.utils.parseEther("1");

    await nftMarketplace.mintNFT("https://token-uri.com", price, { value: listingFee });

    await expect(
      nftMarketplace.connect(buyer).buyNFT(1, { value: price })
    ).to.changeEtherBalances(
      [owner, buyer],
      [price, ethers.utils.parseEther("-1")]
    );

    const newOwner = await nftMarketplace.ownerOf(1);
    expect(newOwner).to.equal(buyer.address);
  });
});
