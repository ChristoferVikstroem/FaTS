const { expect } = require("chai");
const hre = require("hardhat");

/* sample helloworld test with chai.
run all tests in ./test with `npx hardhat test`
refer to chai assertions manual. */


describe("HelloWorld", function () {
  it("Should log Hello World!", async function () {
    const fats = await ethers.deployContract("FaTS");
    await expect(await fats.helloWorld()).to.equal("Hello World!");
  });
})