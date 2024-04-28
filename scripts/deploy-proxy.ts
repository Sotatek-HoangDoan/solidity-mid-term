import {ethers, upgrades } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();
    const Swap = await ethers.getContractFactory('Swap');
    console.log("Deploying Swap ...");
    const swap = await upgrades.deployProxy(
        Swap, 
        [deployer.address, deployer.address, 500],
        { initializer: 'initialize', kind: 'uups' }
    );
    await swap.deploymentTransaction();
    console. log(swap.target," box(proxy) address")
    console. log(await upgrades. erc1967.getImplementationAddress(swap.target.toString()),"getImplementationAddress")
    console.log(await upgrades. erc1967.getAdminAddress(swap.target.toString()),"getAdminAddress" )
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });;