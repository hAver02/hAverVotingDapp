// import { ethers } from 'hardhat';
const { ethers } = require('hardhat')

const deploy = async  () => {
    const [deployer] = await ethers.getSigners();
    console.log("deployer: ", deployer.address);

    const HaverClan = await ethers.getContractFactory("HaverVoting");
    const haverClan = await HaverClan.deploy()
    await haverClan.waitForDeployment();
    const address = await haverClan.getAddress();
    console.log("HaverClan address => ", address);
}   

deploy().then(() => process.exit().catch((err) =>{
    console.log(err);
    process.exit(1)
}))