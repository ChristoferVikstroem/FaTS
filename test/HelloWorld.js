const { expect } = require("chai");
const hre = require("hardhat");

// run all tests in ./test with npx hardhat test
// refer to chai assertions manual

describe("HelloWorld", function () {
    it("Should log Hello World!", async function () {
        const hello = await ethers.deployContract("HelloWorld");
        await expect(await hello.helloWorld()).to.equal("Hello World!");
    });
})