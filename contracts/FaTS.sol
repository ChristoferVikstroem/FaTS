// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract FaTSu {
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

    // Array to store employee details strings
    string[] public employeeDetailsList;

    // A modifier that prevents non-employer users from calling specific functions.
    modifier onlyEmployer() {
        require(msg.sender == employer, "Only the employer can call this function");
        _;
    }

    // Event to log when a new employee is added
    event EmployeeAdded(address employeeAddress, string title, uint256 salary);

    // Event to log when an employee's details are updated
    event EmployeeUpdated(address employeeAddress, string title, uint256 salary);

    // Event to log when an employee verifies their salary
    event SalaryVerified(address employeeAddress, uint256 salary);

    // Constructor to set the employer address
    constructor() {
        employer = msg.sender;
    }

    function getEmployeeAddress(uint256 employeeId) internal view returns (address) {
        for (uint256 i = 0; i < employeeAddresses.length; i++) {
            if (addressToEmployeeId[employeeAddresses[i]] == employeeId) {
                return employeeAddresses[i];
            }
        }
        revert("Employee with the given ID does not exist");
    }

    // Function to add a new employee (only callable by the employer)
    function addEmployee(address employeeAddress, string memory title, uint256 salary) external onlyEmployer {
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

    // Function to get all employee details as an array of strings
    function getAllEmployeeDetails() external view returns (string[] memory) {
        // Initialize the array to store formatted employee details
        string[] memory employeeDetailsArray = new string[](totalEmployees);

        // Populate the array with employee details
        for (uint256 i = 0; i < totalEmployees; i++) {
            address employeeAddress = employeeAddresses[i];
            Employee storage employee = employees[employeeAddress];
            if (employee.salary != 0) {
                // Concatenate employee details to the array
                employeeDetailsArray[i] = string(
                    abi.encodePacked(
                        "*NEW LINE* Identifier: ", toString(employeeAddress), ", Title: ", employee.title,
                        ", Salary: ", uint2str(employee.salary),
                        ", Verified: ", employee.salaryVerified ? " true " : " false "
                    )
                );
            }
        }

        return employeeDetailsArray;
    }

    // Helper function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    // Helper function to convert address to string
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);

