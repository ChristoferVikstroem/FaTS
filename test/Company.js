const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

/* run all tests in ./test with `npx hardhat test` or `hh test`
* refer to chai assertions manual and hardhat chai matchers. 
*/


describe('Company', function () {
  const companyName = 'Google';
  const sector = 'IT';
  const employeeTitle = 'Software Engineer';
  const salary = 60000;

  // fixture for set up only once
  async function defaultFixture() {
    const [companyAccount, employee1, employee2] = await ethers.getSigners();
    const company = await ethers.deployContract("Company", [companyAccount, companyName, sector]);
    return { company, companyAccount, employee1, employee2 }; // fixtures can return anything you consider useful for your tests
  }

  describe('Deployment', function () {
    it('should set the deployer as employer', async function () {
      const { company, companyAccount } = await loadFixture(defaultFixture); // load from fixture
      expect(await company.companyKey()).to.equal(companyAccount.address);
    });
    it('should set the correct initial data.', async function () {
      const { company } = await loadFixture(defaultFixture);
      expect(await company.sector()).to.equal(sector);
      expect(await company.companyName()).to.equal(companyName);
      expect(await company.totalEmployees()).to.equal(0);
      expect(await company.getAverageSalary()).to.equal(0);
    })
  });

  describe('Processing of employees', function () {

    it('should add an employee details correctly', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      expect(await company.totalEmployees()).to.equal(0);
      await expect(await company.addEmployee(employee1.address, employeeTitle, salary)).to.emit(company, 'EmployeeAdded').withArgs(employee1.address, employeeTitle, salary);
      expect(await company.totalEmployees()).to.equal(1);
      await expect(await company.isEmployee(employee1.address)).to.be.true;
    });

    it('should not allow re-registering employees', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      await company.addEmployee(employee1.address, employeeTitle, salary);
      await expect(company.addEmployee(employee1.address, 'Angry But Cute Hedgehog', 37000)).to.be.revertedWith('Address already registered as employee.');
    });

    it('should correctly remove an employee', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      await company.addEmployee(employee1.address, employeeTitle, salary);
      await expect(await company.removeEmployee(employee1.address)).to.emit(company, 'EmployeeRemoved').withArgs(employee1.address, employeeTitle, salary);
      expect(await company.totalEmployees()).to.equal(0);
      await expect(await company.isEmployee(employee1.address)).to.be.false;
    });

    it('should correctly update an employee', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      await company.addEmployee(employee1.address, employeeTitle, salary);
      expect(await company.updateEmployee(employee1.address, 'Professional Clown', 42000)).to.emit(company, 'EmployeeUpdated')
        .withArgs(employee1.address, employeeTitle, 'Professional Clown', salary, 42000);
    });

    it('should not allow bad formatting of employee data', async function () {
      // todo
      //expect(false).to.equal(true);
    });

    it('should not let a non-admin process employee data', async function () {
      const { company, employee1, employee2 } = await loadFixture(defaultFixture);
      await expect(company.connect(employee1).addEmployee(employee2.address, employeeTitle, salary)).to.be.revertedWith('You are not an admin of this company.');
      await company.addEmployee(employee2.address, employeeTitle, salary);
      await expect(company.connect(employee1).removeEmployee(employee2.address)).to.be.revertedWith('You are not an admin of this company.');
      await expect(company.connect(employee1).updateEmployee(employee2.address, "Improper Technician", 42000)).to.be.revertedWith('You are not an admin of this company.');
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
