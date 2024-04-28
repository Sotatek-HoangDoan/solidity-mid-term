import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    "holesky": {
      url: process.env.RPC_ENDPOINT,
      accounts: [String(process.env.PRIVATE_KEY)]
    }
  }
};

export default config;