// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Company {
    // The struct for the employees. Contains their title, salary, and verification of their salary by the employee.
    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    // Maps the employee to their address (digital wallet).
    mapping(address => Employee) public employees;
    mapping(address => uint256) public addressToEmployeeId; //Perhaps not neccessary

    // The employer's address.
    address public employer;

    string public sector;

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
    event EmployeeUpdated(
        address employeeAddress,
        string title,
        uint256 salary
    );

    // Event to log when an employee verifies their salary
    event SalaryVerified(address employeeAddress, uint256 salary);

    // Constructor to set the employer address
    modifier onlyEmployer() {
        require(
            msg.sender == employer,
            "Only the employer can call this function"
        );
        _;
    }

    // Function to add a new employee (only callable by the employer)
    function addEmployee(
        address employeeAddress,
        string memory title,
        uint256 salary
    ) external {
        Employee storage newEmployee = employees[employeeAddress];
        require(
            newEmployee.salary == 0,
            "Employee with the given address already exists"
        );

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
        require(
            existingEmployee.salary != 0,
            "Employee with the given address does not exist"
        );

        // Remove the employee's salary details
        existingEmployee.title = "";
        existingEmployee.salary = 0;
        existingEmployee.salaryVerified = false;

        // Unlink the employee address from the addressToEmployeeId mapping
        addressToEmployeeId[employeeAddress] = 0;

        emit EmployeeUpdated(employeeAddress, "", 0);
    }

    // Function to update an employee's details (only callable by the employer)
    function updateEmployee(
        address employeeAddress,
        string memory title,
        uint256 salary
    ) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeAddress];
        require(
            existingEmployee.salary != 0,
            "Employee with the given address does not exist"
        );

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
        require(
            employee.salary != 0,
            "Employee with the given address does not exist"
        );
        require(
            !employee.salaryVerified,
            "Salary already verified for this employee"
        );

        employee.salaryVerified = true;

        emit SalaryVerified(employeeAddress, employee.salary);
    }

    // Function to get the employee addresses
    function getEmployeeAddresses() public view returns (address[] memory) {
        return employeeAddresses;
    }
}
