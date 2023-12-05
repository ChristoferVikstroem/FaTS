// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract FaTS {
    // The struct for the employees. Contains their title, salary and verification of their salary by the employee.
    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    // Maps the different employees to an employment id.
    mapping(uint256 => Employee) public employees;

    // Maps the employee to an address (digital wallet).
    mapping(address => uint256) public addressToEmployeeId;

    // The employer's address.
    address public employer;

    // A way to track how many employees are currently employed.
    uint256 public totalEmployees;

    // A modifier that prevents non-employer users to call specific functions.
    modifier onlyEmployer() {
        require(
            msg.sender == employer,
            "Only the employer can call this function"
        );
        _;
    }

    // Event to log when a new employee is added
    event EmployeeAdded(uint256 employeeId, string title, uint256 salary);

    // Event to log when an employee's details are updated
    event EmployeeUpdated(uint256 employeeId, string title, uint256 salary);

    // Event to log when an employee verifies their salary
    event SalaryVerified(uint256 employeeId, uint256 salary);

    // Event to log when an employee address is linked to an employee ID
    event EmployeeAddressLinked(uint256 employeeId, address employeeAddress);

    // Constructor to set the employer address
    constructor() {
        employer = msg.sender;
    }

    // Function to add a new employee (only callable by the employer)
    function addEmployee(
        uint256 employeeId,
        string memory title,
        uint256 salary,
        address employeeAddress
    ) external onlyEmployer {
        Employee storage newEmployee = employees[employeeId];
        require(
            newEmployee.salary == 0,
            "Employee with the given ID already exists"
        );

        newEmployee.title = title;
        newEmployee.salary = salary;
        newEmployee.salaryVerified = false;

        // Link the employee address to the employee ID
        addressToEmployeeId[employeeAddress] = employeeId;

        totalEmployees++;

        emit EmployeeAdded(employeeId, title, salary);
        emit EmployeeAddressLinked(employeeId, employeeAddress);
    }

    function getEmployer() external view returns (address) {
        return employer;
    }

    // Function to update an employee's details (only callable by the employer)
    function updateEmployee(
        uint256 employeeId,
        string memory title,
        uint256 salary
    ) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeId];
        require(
            existingEmployee.salary != 0,
            "Employee with the given ID does not exist"
        );

        existingEmployee.title = title;
        existingEmployee.salary = salary;
        // Also resets the verified status of the salary to false since there might be changes.
        existingEmployee.salaryVerified = false;
        emit EmployeeUpdated(employeeId, title, salary);
    }

    // Function for an employee to verify their salary
    function verifySalary() external {
        // Get the employee ID associated with the caller's address
        uint256 employeeId = addressToEmployeeId[msg.sender];
        require(employeeId != 0, "Caller is not linked to any employee ID");
        Employee storage employee = employees[employeeId];
        require(
            employee.salary != 0,
            "Employee with the given ID does not exist"
        );
        require(
            !employee.salaryVerified,
            "Salary already verified for this employee"
        );

        employee.salaryVerified = true;

        emit SalaryVerified(employeeId, employee.salary);
    }

    // Function to get the details of a specific employee
    function getEmployeeDetails(
        uint256 employeeId
    )
        external
        view
        returns (string memory title, uint256 salary, bool salaryVerified)
    {
        Employee storage employee = employees[employeeId];
        require(
            employee.salary != 0,
            "Employee with the given ID does not exist"
        );

        return (employee.title, employee.salary, employee.salaryVerified);
    }

    // Function to get details of all employees
    function getAllEmployeeDetails()
        external
        view
        returns (
            string[] memory titles,
            uint256[] memory salaries,
            bool[] memory salaryVerified
        )
    {
        // Initialize arrays to store employee details
        titles = new string[](totalEmployees);
        salaries = new uint256[](totalEmployees);
        salaryVerified = new bool[](totalEmployees);

        // Populate the arrays with employee details
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalEmployees; i++) {
            Employee storage employee = employees[i];
            if (employee.salary != 0) {
                titles[currentIndex] = employee.title;
                salaries[currentIndex] = employee.salary;
                salaryVerified[currentIndex] = employee.salaryVerified;
                currentIndex++;
            }
        }

        return (titles, salaries, salaryVerified);
    }
}
