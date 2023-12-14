const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

/* run all tests in ./test with `npx hardhat test` or `hh test`
* refer to chai assertions manual and hardhat chai matchers. 
*/


describe('Company', function () {
  const title = "CEO";
  const salary = 60000;

  // fixture for set up only once
  async function defaultFixture() {
    const [owner, account1, account2] = await ethers.getSigners();
    const company = await ethers.deployContract("Company", [owner, "IT"]);
    return { company, owner, account1, account2 }; // fixtures can return anything you consider useful for your tests
  }

  describe('Deployment', function () {
    it('should set the deployer as employer', async function () {
      const { company, owner } = await loadFixture(defaultFixture); // load from fixture
      expect(await company.companyAdmin()).to.equal(owner.address);
    });
    it('should set the correct initial data.', async function () {
      const { company } = await loadFixture(defaultFixture);
      expect(await company.sector()).to.equal("IT");
      expect(await company.totalEmployees()).to.equal(0);
      expect(await company.getAverageSalary()).to.equal(0);
    })
  });

  describe('Admin processing of employees', function () {

    it('should add an employee details correctly', async function () {
      const { company, account1 } = await loadFixture(defaultFixture);
      expect(await company.totalEmployees()).to.equal(0);
      await expect(await company.addEmployee(account1.address, title, salary)).to.emit(company, 'EmployeeAdded').withArgs(account1.address, title, salary);
      expect(await company.totalEmployees()).to.equal(1);
      await expect(await company.isEmployee(account1.address)).to.be.true;
    });

    it('should not allow re-registering employees', async function () {
      const { company, account1 } = await loadFixture(defaultFixture);
      await company.addEmployee(account1.address, title, salary);
      await expect(company.addEmployee(account1.address, 'Software Engineer', 37000)).to.be.revertedWith('Address already registered as employee.');
    });

    it('should correctly remove an employee', async function () {
      const { company, account1 } = await loadFixture(defaultFixture);
      await company.addEmployee(account1.address, title, salary);
      await expect(await company.removeEmployee(account1.address)).to.emit(company, 'EmployeeRemoved').withArgs(account1.address, title, salary);
      expect(await company.totalEmployees()).to.equal(0);
      await expect(await company.isEmployee(account1.address)).to.be.false;
    });

    it('should correctly update an employee', async function () {
      const { company, account1 } = await loadFixture(defaultFixture);
      await company.addEmployee(account1.address, title, salary);
      expect(await company.updateEmployee(account1.address, 'Professional Clown', 42000)).to.emit(company, 'EmployeeUpdated')
        .withArgs(account1.address, title, 'Professional Clown', salary, 42000);
    });

    it('should not allow bad formatting of employee data', async function () {
      // todo
      //expect(false).to.equal(true);
    });

    it('should not let a non-admin process employee data', async function () {
      const { company, account1, account2 } = await loadFixture(defaultFixture);
      await expect(company.connect(account1).addEmployee(account2.address, title, salary)).to.be.revertedWith('You are not an admin of this company.');
      await company.addEmployee(account2.address, title, salary);
      await expect(company.connect(account1).removeEmployee(account2.address)).to.be.revertedWith('You are not an admin of this company.');
      await expect(company.connect(account1).updateEmployee(account2.address, "Improper Technician", 42000)).to.be.revertedWith('You are not an admin of this company.');
    });
  });

  describe('Company metadata', function () {
    it('should display correct average salary', async function () {
      // todo

    });
  });

  describe('Individual employee interaction', function () {
    it('should allow an employee to verify their salary', async function () {
      // todo
    });
  });

});
