const { expect } = require("chai");

describe("NftCollection", function () {

  let nft;
  let owner, addr1, addr2;
beforeEach(async function () {
  const NftCollection = await ethers.getContractFactory("NftCollection");
  [owner, addr1, addr2] = await ethers.getSigners();

  nft = await NftCollection.deploy("MyNFT", "MNFT", 1000);
});


  // -------------------------------------------
  // Test: Initial configuration
  // -------------------------------------------
  it("should initialize name, symbol, maxSupply, and totalSupply == 0", async function () {
    expect(await nft.name()).to.equal("MyNFT");
    expect(await nft.symbol()).to.equal("MNFT");
    expect(await nft.maxSupply()).to.equal(1000);
    expect(await nft.totalSupply()).to.equal(0);
  });

  // -------------------------------------------
  // Test: admin-only minting
  // -------------------------------------------
  it("should revert if non-admin tries to mint", async function () {
    await expect(
      nft.connect(addr1).safeMint(addr1.address, 1)
    ).to.be.reverted;
  });

  // -------------------------------------------
  // Test: successful mint updates totalSupply and balances
  // -------------------------------------------
  it("should allow admin to mint", async function () {
    await nft.safeMint(owner.address, 1);
    expect(await nft.totalSupply()).to.equal(1);
    expect(await nft.balanceOf(owner.address)).to.equal(1);
  });

  // -------------------------------------------
  // Test: transferring tokens updates balances
  // -------------------------------------------
  it("should allow owner to transfer token", async function () {
    await nft.safeMint(owner.address, 1);
    await nft.transferFrom(owner.address, addr1.address, 1);

    expect(await nft.ownerOf(1)).to.equal(addr1.address);
    expect(await nft.balanceOf(owner.address)).to.equal(0);
    expect(await nft.balanceOf(addr1.address)).to.equal(1);
  });

  // -------------------------------------------
  // Test: approvals allow transfer by approved address
  // -------------------------------------------
  it("should allow approved address to transfer", async function () {
    await nft.safeMint(owner.address, 1);
    await nft.approve(addr1.address, 1);

    await nft.connect(addr1).transferFrom(owner.address, addr1.address, 1);

    expect(await nft.ownerOf(1)).to.equal(addr1.address);
  });

  // -------------------------------------------
  // Test: operator approval allows batch transfers
  // -------------------------------------------
  it("should allow operator to transfer tokens", async function () {
    await nft.safeMint(owner.address, 1);
    await nft.safeMint(owner.address, 2);

    await nft.setApprovalForAll(addr1.address, true);

    await nft.connect(addr1).transferFrom(owner.address, addr1.address, 1);
    await nft.connect(addr1).transferFrom(owner.address, addr1.address, 2);

    expect(await nft.balanceOf(addr1.address)).to.equal(2);
  });

  // -------------------------------------------
  // Test: invalid transfers revert
  // -------------------------------------------
  it("should revert for non-existent token", async function () {
    await expect(
      nft.transferFrom(owner.address, addr1.address, 999)
    ).to.be.reverted;
  });

  // -------------------------------------------
  // Test: minting beyond max supply reverts
  // -------------------------------------------
  it("should revert if minting exceeds max supply", async function () {
    await nft.safeMint(owner.address, 1);

    // Set max supply = 1 for this scenario
    const SmallCollection = await ethers.getContractFactory("NftCollection");
    const small = await SmallCollection.deploy("Small", "SM", 1);
    await small.safeMint(owner.address, 1);

    await expect(
      small.safeMint(owner.address, 2)
    ).to.be.reverted;
  });

  // -------------------------------------------
  // Test: event emissions
  // -------------------------------------------
  it("should emit Transfer and Approval events correctly", async function () {
    await expect(nft.safeMint(owner.address, 1))
      .to.emit(nft, "Transfer");

    await expect(nft.approve(addr1.address, 1))
      .to.emit(nft, "Approval");
  });
});
