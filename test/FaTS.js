const { expect } = require("chai");
const hre = require("hardhat");

/* run all tests in ./test with `npx hardhat test` or `hh test`
refer to chai assertions manual. */

describe('FaTS', function () {
  describe('Deployment', function () {
    it('should set owner as employer', async function () {
      const [owner] = await ethers.getSigners();
      const fats = await ethers.deployContract("FaTS");
      expect(await fats.getEmployer()).to.equal(owner.address);
    });
  });
});
