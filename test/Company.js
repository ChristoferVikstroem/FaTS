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

  async function employeeAddedFixture() {
    const [companyAccount, employee1, employee2] = await ethers.getSigners();
    const company = await ethers.deployContract("Company", [companyAccount, companyName, sector]);
    await company.addEmployee(employee1.address, employeeTitle, salary);
    return { company, companyAccount, employee1, employee2 };
  }

  describe('Deployment', function () {
    it('should set the deployer as employer', async function () {
      const { company, companyAccount } = await loadFixture(defaultFixture); // load from fixture
      expect(await company.companyKey()).to.equal(companyAccount.address);
    });

    it('should set the correct initial data', async function () {
      const { company } = await loadFixture(defaultFixture);
      expect(await company.sector()).to.equal(sector);
      expect(await company.companyName()).to.equal(companyName);
      expect(await company.totalEmployees()).to.equal(0);
      expect(await company.getAverageSalary()).to.equal(0);
    });
  });

  describe('Adding an employee', function () {
    it('should correctly set employee details', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      expect(await company.totalEmployees()).to.equal(0);
      await expect(await company.addEmployee(employee1.address, employeeTitle, salary)).to.emit(company, 'EmployeeAdded').withArgs(employee1.address, employeeTitle, salary);
      expect(await company.totalEmployees()).to.equal(1);
      const employee = await company.employees(employee1.address);
      await expect(employee.isEmployee).to.be.true;
    });

    it('can only be done once per address', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      await company.addEmployee(employee1.address, employeeTitle, salary);
      await expect(company.addEmployee(employee1.address, 'Angry But Cute Hedgehog', 37000)).to.be.revertedWith('Already registered employee.');
    });

    it('should not be possible for non-admins', async function () {
      const { company, employee1, employee2 } = await loadFixture(defaultFixture);
      await expect(company.connect(employee1).addEmployee(employee2.address, employeeTitle, salary)).to.be.revertedWith('You are not a company admin.');
    });

    it('should not allow bad parameters', async function () {
      const { company, employee1 } = await loadFixture(defaultFixture);
      await expect(company.addEmployee('0x0000000000000000000000000000000000000000', 'Thursday Tango Instructor', 0)).to.be.revertedWith('Provide valid employee data.');
      await expect(company.addEmployee(employee1.address, '', 0)).to.be.revertedWith('Provide valid employee data.');
    });
  });


  describe('Removing an employee', function () {
    it('should emit correct event parameters.', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      await expect(await company.removeEmployee(employee1.address)).to.emit(company, 'EmployeeRemoved').withArgs(employee1.address, employeeTitle, salary);
    });

    it('should decrement employee count', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      expect(await company.totalEmployees()).to.equal(1);
      await company.removeEmployee(employee1.address);
      expect(await company.totalEmployees()).to.equal(0);
    });

    it('should reset employee struct', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      await company.removeEmployee(employee1.address);
      const employee = await company.employees(employee1.address);
      await expect(employee.isEmployee).to.be.false;
    });

    it('should not be possible for non-admins', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      await expect(company.connect(employee1).removeEmployee(employee1.address)).to.be.revertedWith('You are not a company admin.');
    });

    it('should not be possible for non-existent employee', async function () {
      const { company, employee2 } = await loadFixture(employeeAddedFixture);
      await expect(company.removeEmployee(employee2.address)).to.be.revertedWith('Not a registered employee.');
      expect(await company.totalEmployees()).to.equal(1);
    });
  });


  describe('Updating employee details', function () {
    it('should emit correct event parameters', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      expect(await company.updateEmployee(employee1.address, 'Professional Clown', 42000)).to.emit(company, 'EmployeeUpdated')
        .withArgs(employee1.address, employeeTitle, 'Professional Clown', salary, 42000);
    });

    it('should not allow empty title parameter', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      await expect(company.updateEmployee(employee1.address, '', 0)).to.be.revertedWith('Provide valid employee data.');
    });
    it('should be unable to update non-existing employee', async function () {
      const { company, employee2 } = await loadFixture(employeeAddedFixture);
      await expect(company.updateEmployee(employee2.address, 'Scooby Doo', 50)).to.be.revertedWith('Not a registered employee.');
    });

    it('should not be possible for non-admins', async function () {
      const { company, employee1, employee2 } = await loadFixture(employeeAddedFixture);
      await expect(company.connect(employee2).updateEmployee(employee1.address, "Improper Technician", 42000)).to.be.revertedWith('You are not a company admin.');
    });
  });

  describe('Querying Employee salary', function () {
    it('should get the correct return data', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      var salaryData = await company.getSalary(employee1.address); // 0: salary, 1: title, 2: salaryVerified
      await expect(Number(salaryData[1])).to.equal(salary)
      await expect(salaryData[0]).to.equal(employeeTitle)
      await expect(salaryData[2]).to.be.false;
    });

    it('should be possible to do for anyone', async function () {
      const { company, employee1, employee2 } = await loadFixture(employeeAddedFixture);
      const salaryData = await company.connect(employee2).getSalary(employee1.address); // 0: salary, 1: title, 2: salaryVerified
      await expect(Number(salaryData[1])).to.equal(salary)
      await expect(salaryData[0]).to.equal(employeeTitle)
      await expect(salaryData[2]).to.be.false;
    });

    it('should not be possible for non-existent employee', async function () {
      const { company, employee2 } = await loadFixture(employeeAddedFixture);
      await expect(company.getSalary(employee2.address)).to.be.revertedWith("Not a registered employee.");
    });
  });

  describe('Salary Verification', function () {
    it('should take effect for caller if employed', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      var employee = await company.employees(employee1.address);
      expect(await employee.salaryVerified).to.be.false;
      await company.connect(employee1).verifySalary()
      var employee = await company.employees(employee1.address);
      await expect(await employee.salaryVerified).to.be.true;
    });

    it('should not be possible for non-employee', async function () {
      const { company, employee2 } = await loadFixture(employeeAddedFixture);
      await expect(company.connect(employee2).verifySalary()).to.be.revertedWith('Not a registered employee.');
    });

    it('should only be possible if not already verified', async function () {
      const { company, employee1 } = await loadFixture(employeeAddedFixture);
      var employee = await company.employees(employee1.address);
      await company.connect(employee1).verifySalary();
      var employee = await company.employees(employee1.address);
      await expect(company.connect(employee1).verifySalary()).to.be.revertedWith('Salary already verified.');
    });
  });


  describe('Average salary in Company', function () {
    it('should return correct average for one employee', async function () {
      const { company, employee1, employee2 } = await loadFixture(defaultFixture);
      await company.addEmployee(employee2.address, employeeTitle, 42);
      await expect(await company.getAverageSalary()).to.equal(42);
    });

    it('should return correct average for multiple employees', async function () {
      const { company, employee1, employee2 } = await loadFixture(employeeAddedFixture);
      await company.addEmployee(employee2.address, "CTO", 40000);
      await expect(await company.getAverageSalary()).to.equal(50000);
    });

    it('should return 0 for no employees', async function () {
      const { company } = await loadFixture(defaultFixture);
      await expect(await company.getAverageSalary()).to.equal(0);
    });
  });
});
