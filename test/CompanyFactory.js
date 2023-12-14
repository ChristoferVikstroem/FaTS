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

    // fixture for set up only once
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
        await companyFactory.grantRegistryAccess(companyAddress, companyName, sector);
        return { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress };
    }

    describe('Deployment', function () {
        it('should set deployer as owner,', async function () {
            const { factoryOwner, companyFactory } = await loadFixture(defaultFixture);
            expect(await companyFactory.owner()).to.equal(factoryOwner.address);
        });
    });

    describe('Access rights for company registration', function () {
        it('should give registry rights to a non-registered companyKey.', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await expect(await companyFactory.grantRegistryAccess(companyAddress, companyName, sector)).to.emit(companyFactory, 'RegistryRightChanged')
                .withArgs(companyAddress, companyName, sector, true);
            const registryRight = await companyFactory.registry(companyAddress)
            await expect(registryRight.granted).to.be.true;
            await expect(registryRight.registered).to.be.false;
        })

        it('should not allow an already granted key another right.', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(grantedFixture);
            await expect(companyFactory.grantRegistryAccess(companyAddress, "Scooby Doo", "Detectives")).to.be.revertedWith('Access already granted for this key.');
        });

        it('should not allow granting a right without valid parameters', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await expect(companyFactory.grantRegistryAccess(companyAddress, '', sector)).to.be.revertedWith('Provide valid company data for granting registry access.');
            //await expect(companyFactory.grantRegistryAccess('', companyName, sector)).to.be.revertedWith('Provide valid company data for granting registry access.');
            await expect(companyFactory.grantRegistryAccess(companyAddress, companyName, '')).to.be.revertedWith('Provide valid company data for granting registry access.');

        })
        /*
                it('should allow registering after granting companyKeyAccess', async function () {
                    const { companyFactory, companyAccount } = await loadFixture(defaultFixture);
                    const companyAddress = companyAccount.address;
                    await expect(await companyFactory.grantRegistryAccess(companyAccount, companyName, sector)).to.emit(companyFactory, 'RegistryRightChanged')
                        .withArgs(companyAddress, companyName, sector, true);
                    expect(await companyFactory.connect(companyAccount).registerCompany(companyAddress))
                        .to.emit(companyFactory, 'CompanyRegistered')
                        .withArgs(companyAddress, await companyFactory.companies(companyAddress).address, companyName, sector);
                    expect(await companyFactory.registry(companyAddress).registered()).to.be.true;
                })
        
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
})