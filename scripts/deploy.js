
/* run a script with `npx hardhat run <script>`.
  hardhat will compile your contracts, add the Hardhat Runtime Environment's members to the
  global scope, and execute the script. 
  
  deploy scripts run using `hh run <path-to-script> --network <network-name>`
  (assuming `hh` shortcut installed).
  e.g. `hh run scripts/deploy.js` for hardhat local network */


const hre = require("hardhat"); // can also run scripts via node <script>

async function main() {
  const [deployer] = await ethers.getSigners();
  hre.ethers.getContractFactory
  const fats = await hre.ethers.deployContract("FaTS");
  await fats.waitForDeployment();
  console.log(`FaTS deployed to ${fats.target} from account: ${deployer.address}`);
}

// pattern to use async/await everywhere and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
