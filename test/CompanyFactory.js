const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

/* run all tests in ./test with `npx hardhat test` or `hh test`
* refer to chai assertions manual and hardhat chai matchers. 
*/


describe('CompanyFactory', function () {
    const companyName = 'Google';
    const sector = 'IT';
    const employeeTitle = 'Software Engineer';
    const salary = 60000;

    // fixture for environment set up
    async function defaultFixture() {
        const [factoryOwner, companyAccount, employee1, employee2] = await ethers.getSigners();
        const companyAddress = await companyAccount.address;
        const companyFactory = await ethers.deployContract("CompanyFactory");
        return { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress };
    }

    async function grantedFixture() {
        const [factoryOwner, companyAccount, employee1, employee2] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        const companyAddress = await companyAccount.address;
        await companyFactory.grantRegistryRight(companyAddress, companyName, sector);
        return { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress };
    }

    async function registeredFixture() {
        const [factoryOwner, companyAccount, employee1, employee2] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        const companyAddress = await companyAccount.address;
        await companyFactory.grantRegistryRight(companyAddress, companyName, sector);
        await companyFactory.connect(companyAccount).registerCompany(companyAddress);
        return { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress };
    }

    describe('Deployment', function () {
        it('should set deployer as owner,', async function () {
            const { factoryOwner, companyFactory } = await loadFixture(defaultFixture);
            expect(await companyFactory.owner()).to.equal(factoryOwner.address);
        });
    });

    describe('Access rights', function () {
        it('should give registry rights to a non-registered companyKey.', async function () {
            const { companyFactory, companyAddress } = await loadFixture(defaultFixture);
            await expect(await companyFactory.grantRegistryRight(companyAddress, companyName, sector)).to.emit(companyFactory, 'RegistryRightChanged')
                .withArgs(companyAddress, companyName, sector, true, false);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.granted).to.be.true;
            await expect(registryRight.registered).to.be.false;
        })

        it('should not allow granting a right without valid parameters', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await expect(companyFactory.grantRegistryRight(companyAddress, '', sector)).to.be.revertedWith('Provide valid company data.');
            await expect(companyFactory.grantRegistryRight('0x0000000000000000000000000000000000000000', companyName, sector)).to.be.revertedWith('Provide valid company data.');
            await expect(companyFactory.grantRegistryRight(companyAddress, companyName, '')).to.be.revertedWith('Provide valid company data.');
        });

        it('should not allow an already granted key another right.', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(grantedFixture);
            //await expect(companyFactory.grantRegistryRight(companyAddress, "Scooby Doo", "Detectives")).to.be.revertedWith('Access already granted.');
        });
        /*
        
                it('should set correct Company data.', async function () {
                    //const { companyFactory, company, companyaccount, employee } = loadFixture(companyAddedFixture);
                    const [companyAccount, employee1] = await ethers.getSigners();
                    const companyFactory = await ethers.deployContract("CompanyFactory");
                    await companyFactory.connect(companyAccount).registerCompany(sector);
                    const company = await ethers.getContractAt("Company", await companyFactory.companies(companyAccount.address));
                    await expect(await company.companyAdmin()).to.equal(companyAccount.address);
                });
        
                it('should allow for ')*/

    });
    describe('Registering a company.', function () {
        it('should allow registering after granting companyKey access', async function () {
            const { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress } = await loadFixture(grantedFixture);
            expect(await companyFactory.connect(companyAccount).registerCompany(companyAddress))
                .to.emit(companyFactory, 'CompanyRegistered')
                .withArgs(companyAddress, await companyFactory.companies(companyAddress).address, companyName, sector);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.registered).to.be.true;
        });

        it('should add the registered company to the correct sector', async function () {
            const { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress } = await loadFixture(registeredFixture);
            const sectorCompanies = await companyFactory.companiesBySector(sector);
            expect(sector).to.be.true;

        })
    })
})