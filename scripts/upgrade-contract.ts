const { ethers, upgrades } = require("hardhat");

const PROXY_ADDRESS = "0x9845D84DCcF506D0dEEFfF23cD060A9A12daE511"; //Address of version 1
const VERSION1 = "0xBAC9e4865703fd7f02E412A1CBF7a9DC0c9f6d0D"; //Address of the version 1 implementation

async function main() {
  const Swap = await ethers.getContractFactory("Swap");
  await upgrades.upgradeProxy(
    PROXY_ADDRESS,
    Swap,
    {
      call: {fn: 'reInitialize'},
      kind: "uups"
    }
    );
  console.log("Version 2 deployed.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});