const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy EduChain
  const EduChain = await hre.ethers.getContractFactory("EduChain");
  const eduChain = await EduChain.deploy();
  await eduChain.waitForDeployment();
  const eduChainAddress = await eduChain.getAddress();
  console.log("EduChain deployed to:", eduChainAddress);

  // Deploy BugBounty with EduChain address
  const BugBounty = await hre.ethers.getContractFactory("BugBounty");
  const bugBounty = await BugBounty.deploy(eduChainAddress);
  await bugBounty.waitForDeployment();
  const bugBountyAddress = await bugBounty.getAddress();
  console.log("BugBounty deployed to:", bugBountyAddress);

  // Save the contract addresses for frontend use
  const fs = require("fs");
  const contractAddresses = {
    eduChain: eduChainAddress,
    bugBounty: bugBountyAddress
  };

  const addressDir = "../frontend/src/contracts";
  if (!fs.existsSync(addressDir)) {
    fs.mkdirSync(addressDir, { recursive: true });
  }

  fs.writeFileSync(
    `${addressDir}/addresses.json`,
    JSON.stringify(contractAddresses, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
