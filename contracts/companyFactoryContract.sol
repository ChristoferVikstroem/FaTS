// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract CompanyFactory {
    // Mapping to store companies by sector
    mapping(string => companyContract[]) public companiesBySector;

    // Event to log when a new company is added to a sector
    event CompanyAddedToSector(string sector, address companyAddress);

// Function to create a new company contract and add it to a specific sector
    function createCompany(
        string memory sector,
        string memory title,
        uint256 salary
    ) public returns (address) {
        // Create a new company contract with the caller as the employer
        companyContract newCompany = new companyContract(msg.sender);

        // Add the new company to the sector
        companiesBySector[sector].push(newCompany);

        // Get the address of the new company contract
        address newCompanyAddress = address(newCompany);

        // Emit the event with the address of the new company
        emit CompanyAddedToSector(sector, newCompanyAddress);

        // Call the addEmployee function in the new company contract
        newCompany.addEmployee(msg.sender, title, salary);

        // Return the address of the newly created company contract
        return newCompanyAddress;
    }
    // Function to get the total number of companies in a sector
    function getCompanyCountInSector(string memory sector) public view returns (uint256) {
        return companiesBySector[sector].length;
    }

    // Function to get the details of a company in a specific sector by index
    function getCompanyDetailsInSector(string memory sector, uint256 index)
    public
    view
    returns (
        address employer,
        uint256 totalEmployees,
        address[] memory employeeAddresses,
        uint256 averageSalary
    )
{
    require(index < companiesBySector[sector].length, "Index out of bounds");

    companyContract company = companiesBySector[sector][index];
    address companyAddress = address(company);

    employeeAddresses = company.getEmployeeAddresses();
    totalEmployees = company.totalEmployees();
    averageSalary = company.getAverageSalary();

    return (companyAddress, totalEmployees, employeeAddresses, averageSalary);
}

    // Function to get the average salary of employees in a sector
    function getAverageSalaryInSector(string memory sector) public view returns (uint256) {
        uint256 totalSalaries;
        uint256 totalEmployees;

        for (uint256 i = 0; i < companiesBySector[sector].length; i++) {
            companyContract company = companiesBySector[sector][i];
            totalSalaries += company.getAverageSalary();
            totalEmployees += company.totalEmployees();
        }

        if (totalEmployees > 0) {
            return totalSalaries / totalEmployees;
        } else {
            return 0;
        }
    }
}

contract companyContract {
    // The struct for the employees. Contains their title, salary, and verification of their salary by the employee.
    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    // Maps the employee to their address (digital wallet).
    mapping(address => Employee) public employees;
    mapping(address => uint256) public addressToEmployeeId;

    // The employer's address.
    address public employer;

    // A way to track how many employees are currently employed.
    uint256 public totalEmployees;

    // Array to store employee addresses
    address[] public employeeAddresses;

    // A modifier that prevents non-employer users from calling specific functions.
     constructor(address _employer) {
        employer = _employer;
    }

    // Event to log when a new employee is added
    event EmployeeAdded(address employeeAddress, string title, uint256 salary);

    // Event to log when an employee's details are updated
    event EmployeeUpdated(address employeeAddress, string title, uint256 salary);

    // Event to log when an employee verifies their salary
    event SalaryVerified(address employeeAddress, uint256 salary);

    // Constructor to set the employer address
      modifier onlyEmployer() {
        require(msg.sender == employer, "Only the employer can call this function");
        _;
    }

    // Function to add a new employee (only callable by the employer)
      function addEmployee(address employeeAddress, string memory title, uint256 salary) external {
        Employee storage newEmployee = employees[employeeAddress];
        require(newEmployee.salary == 0, "Employee with the given address already exists");

        newEmployee.title = title;
        newEmployee.salary = salary;
        newEmployee.salaryVerified = false;
        totalEmployees++;

        // Add the employee address to the addressToEmployeeId mapping
        addressToEmployeeId[employeeAddress] = totalEmployees;

        // Add the employee address to the employeeAddresses array
        employeeAddresses.push(employeeAddress);

        emit EmployeeAdded(employeeAddress, title, salary);
    }

    // Function to get the average salary of employees in the company
    function getAverageSalary() external view returns (uint256) {
        uint256 totalSalary;

        for (uint256 i = 0; i < employeeAddresses.length; i++) {
            address employeeAddress = employeeAddresses[i];
            totalSalary += employees[employeeAddress].salary;
        }

        if (totalEmployees > 0) {
            return totalSalary / totalEmployees;
        } else {
            return 0;
        }
    }

    // Function to remove an employee (only callable by the employer)
    function removeEmployee(address employeeAddress) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeAddress];
        require(existingEmployee.salary != 0, "Employee with the given address does not exist");

        // Remove the employee's salary details
        existingEmployee.title = "";
        existingEmployee.salary = 0;
        existingEmployee.salaryVerified = false;

        // Unlink the employee address from the addressToEmployeeId mapping
        addressToEmployeeId[employeeAddress] = 0;

        emit EmployeeUpdated(employeeAddress, "", 0);
    }

    // Function to update an employee's details (only callable by the employer)
    function updateEmployee(address employeeAddress, string memory title, uint256 salary) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeAddress];
        require(existingEmployee.salary != 0, "Employee with the given address does not exist");

        existingEmployee.title = title;
        existingEmployee.salary = salary;
        // Also resets the verified status of the salary to false since there might be changes.
        existingEmployee.salaryVerified = false;
        emit EmployeeUpdated(employeeAddress, title, salary);
    }

    // Function for an employee to verify their salary
    function verifySalary() external {
        address employeeAddress = msg.sender;
        Employee storage employee = employees[employeeAddress];
        require(employee.salary != 0, "Employee with the given address does not exist");
        require(!employee.salaryVerified, "Salary already verified for this employee");

        employee.salaryVerified = true;

        emit SalaryVerified(employeeAddress, employee.salary);
    }

    // Function to get the employee addresses
    function getEmployeeAddresses() public view returns (address[] memory) {
        return employeeAddresses;
    }
}
