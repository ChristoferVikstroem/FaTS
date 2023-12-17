const chai = require('chai');
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
const { expect } = chai;

describe('CompanyFactory', function () {
    const companyName = 'Google';
    const sector = 'IT';
    const employeeTitle = 'Software Engineer';
    const salary = 60000;

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

    async function manyGrantedFixture() {
        const [factoryOwner, company1, company2, company3, employee1, employee2] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        const companyAddress = await companyAccount.address;
        await companyFactory.grantRegistryRight(company1, 'Google', sector);
        await companyFactory.grantRegistryRight(company2, 'Noogle', sector);
        await companyFactory.grantRegistryRight(company3, 'The Coffice', 'Fine Dining');
        return { companyFactory, factoryOwner, companyAddress, company1, company2, company3, employee1, employee2 };
    }

    async function registeredFixture() {
        const [factoryOwner, companyAccount, employee1, employee2] = await ethers.getSigners();
        const companyFactory = await ethers.deployContract("CompanyFactory");
        const companyAddress = await companyAccount.address;
        await companyFactory.grantRegistryRight(companyAddress, companyName, sector);
        await companyFactory.connect(companyAccount).registerCompany(companyAddress);
        return { companyFactory, companyAccount, employee1, employee2, factoryOwner, companyAddress };
    }
    async function manyRegisteredFixture() {
        const { factoryOwner, company1, company2, company3, employee1, employee2 } = await loadFixture(manyGrantedFixture);
        await companyFactory.connect(company1).registerCompany(company1.address);
        await companyFactory.connect(company2).registerCompany(company2.address);
        await companyFactory.connect(company3).registerCompany(company3.address);
        return { companyFactory, factoryOwner, companyAddress, company1, company2, company3, employee1, employee2 };
    }


    describe('Deployment', function () {
        it('should set deployer as owner,', async function () {
            const { factoryOwner, companyFactory } = await loadFixture(defaultFixture);
            expect(await companyFactory.owner()).to.equal(factoryOwner.address);
        });
    });

    describe('Granting registry right', function () {
        it('should grant registry right to a non granted and non-registered key', async function () {
            const { companyFactory, companyAddress } = await loadFixture(defaultFixture);
            await expect(await companyFactory.grantRegistryRight(companyAddress, companyName, sector)).to.emit(companyFactory, 'RegistryRightChanged')
                .withArgs(companyAddress, companyName, sector, true, false);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.granted).to.be.true;
            await expect(registryRight.registered).to.be.false;
        });

        it('should not be possible for bad Company parameters', async function () {
            const { companyFactory, companyAddress } = await loadFixture(defaultFixture);
            await expect(companyFactory.grantRegistryRight(companyAddress, '', sector)).to.be.revertedWith('Provide valid company data.');
            await expect(companyFactory.grantRegistryRight('0x0000000000000000000000000000000000000000', companyName, sector)).to.be.revertedWith('Provide valid company data.');
            await expect(companyFactory.grantRegistryRight(companyAddress, companyName, '')).to.be.revertedWith('Provide valid company data.');
        });

        it('should not be possible for an already granted key', async function () {
            const { companyFactory, companyAddress } = await loadFixture(grantedFixture);
            await expect(companyFactory.grantRegistryRight(companyAddress, "Scooby Doo", "Detectives")).to.be.revertedWith('Registry right already granted.');
        });

        it('should not be possible for an already registered Company', async function () {
            const { companyFactory, companyAddress } = await loadFixture(registeredFixture);
            await expect(companyFactory.grantRegistryRight(companyAddress, "Scooby Doo", "Detectives")).to.be.revertedWith('Company already registered.');
        });

        it('should only be possible for contract owner', async function () {
            const { companyFactory, companyAddress, employee1 } = await loadFixture(grantedFixture);
            await expect(companyFactory.connect(employee1).grantRegistryRight(companyAddress, "Egg Pickers LTD", "Farming")).to.be.revertedWith('Not owner.');
        });
    });

    describe('Revoking registry right', function () {
        it('should be possible if granted but not yet registered', async function () { // todo; fails...
            const { companyFactory, factoryOwner, companyAddress } = await loadFixture(grantedFixture);
            await companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.granted).to.be.false;
        });

        it('should not be possible for a company without registry access.', async function () {
            const { companyFactory, factoryOwner, companyAddress } = await loadFixture(defaultFixture);
            await expect(companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress)).to.be.revertedWith('No registry access granted.');
        });

        it('should not be possible for already registered company', async function () {
            const { companyFactory, factoryOwner, companyAddress } = await loadFixture(registeredFixture);
            await expect(companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress)).to.be.revertedWith('No registry access granted.');
        });

        it('should be possible for non-owner', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await companyFactory.grantRegistryRight(companyAddress, 'Poodle', sector);
            await expect(companyFactory.connect(companyAccount).revokeRegistryRight(companyAddress)).to.be.revertedWith('Not owner.');
        });
    });

    describe('Registering a Company', function () {
        it('should not be possible without granted register access', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('No register access granted.');
        });

        it('should be possible after granting key access', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(grantedFixture);
            expect(await companyFactory.connect(companyAccount).registerCompany(companyAddress))
                .to.emit(companyFactory, 'CompanyRegistered')
                .withArgs(companyAddress, await companyFactory.companies(companyAddress).address, companyName, sector);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.registered).to.be.true;
        });

        it('should not be possible after revoking registry right', async function () {
            const { companyFactory, factoryOwner, companyAccount, companyAddress } = await loadFixture(grantedFixture);
            await companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress);
            await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('No register access granted.');
        });

        it('should not be possible for an already registered company', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(registeredFixture);
            await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('Company already registered.');
        });

        it('should add the registered company to the correct sector', async function () {
            const { companyFactory, companyAddress } = await loadFixture(registeredFixture);
            var companyDetails = await companyFactory.getCompanyDetails(companyAddress);
            expect(companyDetails[1]).to.equal(sector);
        });
    });

    describe('Removing a Company', function () {
        it('should not be possible for an unregistered company', async function () {
            const { companyFactory, companyAddress, factoryOwner } = await loadFixture(defaultFixture);
            await expect(companyFactory.connect(factoryOwner).removeCompany(companyAddress)).to.be.revertedWith("No company registered for key.");
        });

        it('should be possible for the Company owner', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(registeredFixture);
            await companyFactory.connect(companyAccount).removeCompany(companyAddress)
            await expect(companyFactory.getCompanyDetails(companyAddress)).to.be.revertedWith("No such company registered.");
        });


        it('should be possible for the Factory owner', async function () {
            const { companyFactory, factoryOwner, companyAddress } = await loadFixture(registeredFixture);
            await companyFactory.connect(factoryOwner).removeCompany(companyAddress)
            await expect(companyFactory.getCompanyDetails(companyAddress)).to.be.revertedWith("No such company registered.");
        });

    });


    describe('Querying Company details', function () {
        it('should return correct details for a registered company with no added employees', async function () {
            const { companyFactory, companyAddress } = await loadFixture(registeredFixture);
            var details = await companyFactory.getCompanyDetails(companyAddress);
            await expect([details[0], details[1], Number(details[2]), Number(details[3])]).to.deep.equal([companyName, sector, Number(0), Number(0)]);
        });

        it('should return correct details for a registered company with added employees', async function () {
            const { companyFactory, companyAccount, companyAddress, employee1, employee2 } = await loadFixture(grantedFixture);
            const registerTransaction = await companyFactory.connect(companyAccount).registerCompany(companyAddress);
            await registerTransaction.wait();

            // Ensure that the companies mapping is properly populated after registration
            const companyObject = companyFactory.companies[companyAddress];
            await 
            const company = await ethers.getContractAt("Company", address(companyFactory.companies[companyAddress]));

            await company.connect(companyAccount).addEmployee(employee1.address, "Sales", 42000);
            await company.connect(companyAccount).addEmployee(employee2.address, "Event Manager", 100000);

            const details = await companyFactory.getCompanyDetails(companyAddress);

            // Assuming companyName and sector are defined somewhere in your code
            await expect([details[0], details[1], Number(details[2]), Number(details[3]) / 2])
                .to.deep.equal([companyName, sector, Number(2), Number((42000 + 100000) / 2)]);
        });


    });

    describe('Querying Company addresses in a sector', function () {
        it('should return no addresses for sector with no companies', async function () {
            const { companyFactory } = await loadFixture(defaultFixture);
            const companies = await companyFactory.getCompanyAddressesInSector('NonexistentSector');
            expect(companies).to.deep.equal([]);
        });
        it('should handle registering multiple companies in different sectors', async function () {
            const { companyFactory, factoryOwner, company1, company2, company3, employee1, employee2 } = await loadFixture(manyGrantedFixture);
            await companyFactory.connect(company1).registerCompany(company1.address);
            await companyFactory.connect(company2).registerCompany(company2.address);
            await companyFactory.connect(company3).registerCompany(company3.address);
            const ITSector = await companyFactory.getCompanyAddressesInSector('IT');
            const sector2 = await companyFactory.getCompanyAddressesInSector('Fine Dining');
            expect(ITSector).to.deep.equal([company1.address, company2.address]);
            expect(sector2).to.deep.equal([company3.address]);
        });
    })

    describe('Querying average salaries in sector', function () {
        it('should return 0 for sector with no companies', async function () {
            const { companyFactory } = await loadFixture(defaultFixture);
            const averageSalary = await companyFactory.getAverageSalaryInSector(sector);
            expect(averageSalary).to.equal(0);
        });

        it('should return 0 for sector with no employees', async function () {
            const { companyFactory } = await loadFixture(registeredFixture);
            const averageSalary = await companyFactory.getAverageSalaryInSector(sector);
            expect(averageSalary).to.equal(0);
        });

        it('should revert for a sector with no companies', async function () { // todo should it really??
            const { companyFactory } = await loadFixture(defaultFixture);
            expect(await companyFactory.getAverageSalaryInSector('fakeTestSector')).to.be.revertedWith('The sector has no registered companies.');
        });

        it('should handle getAverageSalaryInSector with multiple companies', async function () {
            const { companyFactory, factoryOwner, company1, company2, company3, employee1, employee2 } = await loadFixture(manyRegisteredFixture);
            //const contract1 = await ethers.getContractAt("Company", company1.add);
            await company.connect(companyAccount).addEmployee(employee1.address, "CEO", 10000);
            await company.connect(companyAccount).addEmployee(employee2.address, "CTO", 10000);
            const averageSalary = await expect(companyFactory.getAverageSalaryInSector(sector)).to.be.fulfilled;
            const expectedSalary = 10000;
            expect(Number(averageSalary)).to.equal(expectedSalary);
        });
    });
});
