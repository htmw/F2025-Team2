const hre = require("hardhat");

async function main() {
  console.log("Deploying Crowdfunding...");

  const target = hre.ethers.utils.parseEther("1"); // 1 ETH
  const seconds = 10368000; // 120 days

  const Crowdfunding = await hre.ethers.getContractFactory("Crowdfunding");
  const contract = await Crowdfunding.deploy(target, seconds);

  console.log("TX Hash:", contract.deployTransaction.hash);
  await contract.deployTransaction.wait(1);

  console.log("✅ Deployed at:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
