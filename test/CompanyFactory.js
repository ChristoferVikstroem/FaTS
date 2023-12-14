const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

/* run all tests in ./test with `npx hardhat test` or `hh test`
* refer to chai assertions manual and hardhat chai matchers. 
*/


describe('CompanyFactory', function () {
    const sector = 'IT';
    const title = "CEO";
    const salary = 60000;

    // fixture for set up only once
    async function defaultFixture() {
        const [owner, account1, account2] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        return { companyFactory, owner, account1, account2 };
    }

    async function companyAddedFixture() {
        const [employer, employee] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        await companyFactory.connect(employer).createCompany(sector);
        const company = await companyFactory.companies(employer.address);
        return { companyFactory, company, employer, employee };
    }


    describe('Deployment', function () {
        it('should set deployer as owner', async function () {
            const { companyFactory, owner } = await loadFixture(defaultFixture);
            expect(await companyFactory.owner()).to.equal(owner.address);
        });
    });

    describe('Creating Company', function () {
        it('should emit correct data and register a the companyAdmin as registered.', async function () {
            const { companyFactory, account1 } = await loadFixture(defaultFixture);
            expect(await companyFactory.connect(account1).createCompany(sector))
                .to.emit(companyFactory, 'CompanyAdded')
                .withArgs(account1.address, await companyFactory.companies(account1.address).address, sector);
            expect(await companyFactory.isRegistered(account1.address)).to.be.true;
        });

        it('should set correct Company data.', async function () {
            //const { companyFactory, company, employer, employee } = loadFixture(companyAddedFixture);
            const [employer, employee] = await ethers.getSigners();
            const companyFactory = await ethers.deployContract("CompanyFactory");
            await companyFactory.connect(employer).createCompany(sector);
            const company = await ethers.getContractAt("Company", await companyFactory.companies(employer.address));
            await expect(await company.companyAdmin()).to.equal(employer.address);
            // todo
        })

    });
})