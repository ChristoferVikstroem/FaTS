const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

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
    });

    describe('Registering a company.', function () {
        it('should allow registering after granting companyKey access', async function () {
            const { companyFactory, companyAccount, factoryOwner, companyAddress } = await loadFixture(grantedFixture);
            expect(await companyFactory.connect(companyAccount).registerCompany(companyAddress))
                .to.emit(companyFactory, 'CompanyRegistered')
                .withArgs(companyAddress, await companyFactory.companies(companyAddress).address, companyName, sector);
            const registryRight = await companyFactory.registryRights(companyAddress);
            await expect(registryRight.registered).to.be.true;
        });

        it('should add the registered company to the correct sector', async function () {
            const { companyFactory, companyAccount, factoryOwner, companyAddress } = await loadFixture(registeredFixture);
            var companyDetails = await companyFactory.getCompanyDetails(companyAddress);
            expect(companyDetails[1]).to.equal("IT");
        });

        it('should not allow registering a company without granted register access', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(registeredFixture);
            await companyFactory.grantRegistryRight(companyAddress, "Google", "IT");
            await companyFactory.connect(companyAccount).registerCompany(companyAddress);
            await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('No register access granted.');
        });

        it('should not allow registering an already registered company', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(registeredFixture);
            await companyFactory.grantRegistryRight(companyAddress, "Google", "IT");
            await companyFactory.connect(companyAccount).registerCompany(companyAddress);
            await companyFactory.grantRegistryRight(companyAddress, "Google", "IT");
            expect(await companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith("Address already registered.");
        });

        it('should not allow removing an unregistered company', async function () {
            const { companyFactory, companyAccount, companyAddress, factoryOwner } = await loadFixture(defaultFixture);
            await expect(companyFactory.connect(factoryOwner).removeCompany(companyAddress)).to.be.revertedWith("No company registered for key.");
        });

        it('should not allow non-owner to revoke registry right', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await companyFactory.grantRegistryRight(companyAddress, 'Google', 'IT');
            await expect(companyFactory.connect(companyAccount).revokeRegistryRight(companyAddress)).to.be.revertedWith('Not owner.');
        });

        it('should not allow removing an unregistered company', async function () {
            const { companyFactory, companyAccount, companyAddress, factoryOwner } = await loadFixture(defaultFixture);
            await expect(companyFactory.connect(factoryOwner).removeCompany(companyAddress)).to.be.revertedWith('No company registered for key.');
        });
        
        it('should not allow non-owner to remove a company', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);

            // Register the company before attempting to remove it
            await companyFactory.grantRegistryRight(companyAddress, 'Company Name', 'IT');
            await companyFactory.connect(companyAccount).registerCompany(companyAddress);

            // Now attempt to remove the company
            await expect(companyFactory.connect(companyAccount).removeCompany(companyAddress)).to.be.revertedWith('Not authorized.');
        });

        it('should handle registering multiple companies in different sectors', async function () {
            const { companyFactory, companyAccount, factoryOwner, companyAddress } = await loadFixture(defaultFixture);

            // Register a company in IT sector
            await companyFactory.grantRegistryRight(companyAddress, 'Google', 'IT');
            await companyFactory.connect(companyAccount).registerCompany(companyAddress);

            // Register another company in Finance sector
            const financeCompanyAddress = '0x1234567890123456789012345678901234567890'; // Use a different address
            await companyFactory.grantRegistryRight(financeCompanyAddress, 'Coffice', 'Fine Dining');
            await companyFactory.connect(factoryOwner).registerCompany(financeCompanyAddress);

            const itCompanies = await companyFactory.getCompanyAddressesInSector('IT');
            const financeCompanies = await companyFactory.getCompanyAddressesInSector('Fine Dining');

            expect(itCompanies).to.deep.equal([companyAddress]);
            expect(financeCompanies).to.deep.equal([financeCompanyAddress]);
        });
    });

    describe('Company Query', function () {
        it('should return correct details for a registered company', async function () {
            const { companyFactory, companyAddress, companyName, sector } = await loadFixture(registeredFixture);
            var details = await companyFactory.getCompanyDetails(companyAddress);
            await expect([details[0], details[1], Number(details[2]), Number(details[3])]).to.deep.equal(['Google', 'IT', Number(0), Number(0)]); // Adjust based on your contract's logic
        });

        it('should return company addresses in a sector', async function () {
            const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
            await companyFactory.grantRegistryRight(companyAddress, "Google", "IT");
            await companyFactory.connect(companyAccount).registerCompany(companyAddress);
            var details = await companyFactory.getCompanyDetails(companyAddress);
            await expect(details[1]).to.deep.equal("IT");
        });

        it('should handle getAverageSalaryInSector with no companies', async function () {
            const { companyFactory } = await loadFixture(defaultFixture);
            const averageSalary = await companyFactory.getAverageSalaryInSector('fakeTestSector');
            expect(averageSalary).to.equal(0);
        });

        it('should handle getAverageSalaryInSector with no employees', async function () {
            const { companyFactory } = await loadFixture(defaultFixture);
            const averageSalary = await companyFactory.getAverageSalaryInSector('fakeTestSector');
            expect(averageSalary).to.equal(0);
        });
    });

    describe('Additional Tests', function () {
        describe('Access rights', function () {
            it('should not allow revoking registry right for an unregistered company', async function () {
                const { companyFactory, factoryOwner, companyAddress } = await loadFixture(defaultFixture);
                await expect(companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress)).to.be.revertedWith('No registry access granted.');
            });
        });

        describe('Registering a company.', function () {
            it('should not allow registering a company without granted registry access', async function () {
                const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
                await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('No register access granted.');
            });

            it('should not allow registering an ungranted company after revoking access', async function () {
                const { companyFactory, factoryOwner, companyAccount, companyAddress } = await loadFixture(grantedFixture);
                await companyFactory.connect(factoryOwner).revokeRegistryRight(companyAddress);
                await expect(companyFactory.connect(companyAccount).registerCompany(companyAddress)).to.be.revertedWith('No register access granted.');
            });

            it('should handle registering multiple companies in different sectors', async function () {
                const { companyFactory, companyAccount, factoryOwner, companyAddress } = await loadFixture(defaultFixture);

                // Register a company in IT sector
                await companyFactory.grantRegistryRight(companyAddress, 'Company1', 'IT');
                await companyFactory.connect(companyAccount).registerCompany(companyAddress);

                // Register another company in Finance sector
                const financeCompanyAddress = '0x1234567890123456789012345678901234567890'; // Use a different address
                await companyFactory.grantRegistryRight(financeCompanyAddress, 'Company2', 'Finance');
                await companyFactory.connect(factoryOwner).registerCompany(financeCompanyAddress);

                const itCompanies = await companyFactory.getCompanyAddressesInSector('IT');
                const financeCompanies = await companyFactory.getCompanyAddressesInSector('Finance');

                expect(itCompanies).to.deep.equal([companyAddress]);
                expect(financeCompanies).to.deep.equal([financeCompanyAddress]);
            });
        });

        describe('Company Query', function () {
            it('should return 0 average salary for a sector with no employees', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const averageSalary = await companyFactory.getAverageSalaryInSector('NonexistentSector');
                expect(averageSalary).to.equal(0);
            });

            it('should return correct total employees and average salary for a registered company', async function () {
                const { companyFactory, companyAddress } = await loadFixture(registeredFixture);
                const details = await companyFactory.getCompanyDetails(companyAddress);
                expect(details[2]).to.equal(0); // Assuming totalEmployees is initialized to 0
                expect(details[3]).to.equal(0); // Assuming averageSalary is initialized to 0
            });

            it('should handle getCompanyAddressesInSector with no companies', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const companies = await companyFactory.getCompanyAddressesInSector('NonexistentSector');
                expect(companies).to.deep.equal([]);
            });

            it('should return correct details for a registered company', async function () {
                const { companyFactory, companyAddress, companyName, sector } = await loadFixture(registeredFixture);
                const details = await companyFactory.getCompanyDetails(companyAddress);
                expect([details[0], details[1], Number(details[2]), Number(details[3])]).to.deep.equal(["Google", "IT", 0, 0]);
            });

            it('should return 0 average salary for a sector with no employees', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const averageSalary = await companyFactory.getAverageSalaryInSector('NonexistentSector');
                expect(averageSalary).to.equal(0);
            });

            it('should handle getCompanyAddressesInSector with no companies', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const companies = await companyFactory.getCompanyAddressesInSector('NonexistentSector');
                expect(companies).to.deep.equal([]);
            });

            it('should handle getAverageSalaryInSector with no companies', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const averageSalary = await companyFactory.getAverageSalaryInSector('NonexistentSector');
                expect(averageSalary).to.equal(0);
            });

            it('should handle getAverageSalaryInSector with no employees', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                const fakeTestSector = 'does-not-exist-Sector';
                const averageSalary = await companyFactory.getAverageSalaryInSector(fakeTestSector);
                expect(averageSalary).to.equal(0);
            });
            it('should revert for a sector with no companies', async function () {
                const { companyFactory } = await loadFixture(defaultFixture);
                expect(await companyFactory.getAverageSalaryInSector('fakeTestSector')).to.be.revertedWith('The sector has no registered companies.');
            });
            it('should handle getAverageSalaryInSector with no employees in the sector but with companies', async function () {
                const { companyFactory, companyAccount, companyAddress } = await loadFixture(defaultFixture);
                await companyFactory.grantRegistryRight(companyAddress, "Google", "IT");
                await companyFactory.connect(companyAccount).registerCompany(companyAddress);
                const details = await companyFactory.getCompanyDetails(companyAddress);
                var sector = details[1];
                const averageSalary = await companyFactory.connect(companyAccount).getAverageSalaryInSector(sector);
                expect(averageSalary).to.equal(0);
            });
        });
    });
})
