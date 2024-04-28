import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import Erc20 from "../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json";
import { parseEther } from "ethers";
const {deployMockContract} = require('@ethereum-waffle/mock-contract');


describe("Swap", function () {
  async function deploySwapTexture() {
    const FEE = 500;

    const [deployer,requester, partner] = await ethers.getSigners();
    const mockPayToken = deployMockContract(deployer, Erc20.abi);
    const mockRequestToken = deployMockContract(deployer, Erc20.abi);
    
    const Swap = await ethers.getContractFactory("Swap");
    const swapInstance = await upgrades.deployProxy(Swap, [deployer.address, deployer.address, FEE], { initializer: 'initialize', kind: 'uups' });

    return { deployer, requester, partner, mockPayToken, mockRequestToken, swapInstance}
  }

  describe("Update fee", function () {
    it("Should be right owner", async () => {
      const { deployer, swapInstance } = await deploySwapTexture();
      expect(await swapInstance.owner()).to.equal(deployer.address);
    })

    it("Should update successfully by owner",async () => {
      const {deployer, swapInstance} = await loadFixture(deploySwapTexture);
      await swapInstance.connect(deployer).updateFee(100);
      expect(await swapInstance.fee()).to.equal(100);
    })

    // it("Should update failed by not owner",async () => {
    //   const {requester, swapInstance} = await loadFixture(deploySwapTexture);
    //   expect(await swapInstance.connect(requester).updateFee(100)).to.reverted('string')
      
    // })
  })

  describe("Update treasury", function () {
    it("Should be right owner", async () => {
      const { deployer, swapInstance } = await deploySwapTexture();
      expect(await swapInstance.owner()).to.equal(deployer.address);
    })

    it("Should update successfully by owner",async () => {
      const {deployer, requester, swapInstance} = await loadFixture(deploySwapTexture);
      await swapInstance.connect(deployer).updateTreasury(requester.address);
      expect(await swapInstance.treasury()).to.equal(requester.address);
    })

    it("Should update faild by owner with zero address",async () => {
      const {deployer, swapInstance} = await loadFixture(deploySwapTexture);
      expect(await swapInstance.connect(deployer).updateTreasury("0x0000000000000000000000000000000000000000")).to.be.revertedWith("Treasury must be a valid address");
      
    })
    // it("Should update failed by not owner",async () => {
    //   const {requester, swapInstance} = await loadFixture(deploySwapTexture);
    //   expect(await swapInstance.connect(requester).updateFee(100)).to.reverted('string')
      
    // })
  })

  describe("Create request", () => {
    it("Should be created successfully swap request", async () => {
      const {requester, partner, mockPayToken, mockRequestToken, swapInstance } = await loadFixture(deploySwapTexture);
      await mockPayToken.mock.balances.returns(parseEther("1000"));
      expect (await swapInstance.connect(requester).create(partner.address, mockPayToken.address, mockRequestToken.address, parseEther("1000"), parseEther("1000"))).to.be.emit(swapInstance, 'SwapRequestCreated');
    })
  })
});
