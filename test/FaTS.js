const { expect } = require("chai");
const hre = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

/* run all tests in ./test with `npx hardhat test` or `hh test`
refer to chai assertions manual and hardhat chai matchers. 

example use
await expect(token.transfer(recipient, 1000))
  .to.emit(token, "Transfer")
  .withArgs(owner, recipient, 1000);
*/


describe('FaTS', function () {
  // fixture for set up only once
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const fats = await ethers.deployContract("FaTS");
    return { fats, owner, addr1, addr2 }; // fixtures can return anything you consider useful for your tests
  }

  describe('Deployment', function () {
    it('should set owner as employer', async function () {
      const { fats, owner } = await loadFixture(deployFixture); // load from fixture
      expect(await fats.getEmployer()).to.equal(owner.address);
    });
  });
});
