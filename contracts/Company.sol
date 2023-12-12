// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/* todo: proper use of memory, calldata, storage
 * memory is used to store temporary data that is needed during the execution of a function.
 * calldata is used to store function arguments that are passed in from an external caller.
 * storage is used to store data permanently on the blockchain.
 */

contract Company {
    // variables, structs, mappings..
    address public employer; // todo decide on name: employer or companyAdmin, use same in both contracts.
    string public sector; // final
    uint256 public totalEmployees;
    address[] public employeeAddresses; // todo: remove? we have this info in the mapping
    mapping(address => Employee) public employees;
    mapping(address => uint256) public addressToEmployeeId; // perhaps not neccessary / christofer

    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    event EmployeeAdded(address employeeAddress, string title, uint256 salary);
    event SalaryVerified(address employeeAddress, uint256 salary);
    event EmployeeUpdated(
        address employeeAddress,
        string title,
        uint256 salary
    );

    // Constructor to set the employer address
    modifier onlyEmployer() {
        // todo: add functionality to add/remove employers/admins?
        require(
            msg.sender == employer,
            "You are not an admin of this company."
        );
        _;
    }

    // A modifier that prevents non-employer users from calling specific functions.
    constructor(address _employer, string memory _sector) {
        employer = _employer;
        sector = _sector;
    }

    // employee functionality

    function addEmployee(
        address employeeAddress,
        string memory title,
        uint256 salary
    ) external {
        Employee storage newEmployee = employees[employeeAddress];
        require(
            newEmployee.salary == 0,
            "Employee with the given address already exists"
        ); // todo: check if key exists instead, or use mappin: isEmployed.

        newEmployee.title = title;
        newEmployee.salary = salary;
        newEmployee.salaryVerified = false;
        totalEmployees++;

        // add the employee address to the addressToEmployeeId mapping
        // todo seems incorrect & change functionality to mapping
        addressToEmployeeId[employeeAddress] = totalEmployees;
        employeeAddresses.push(employeeAddress);
        emit EmployeeAdded(employeeAddress, title, salary);
    }

    // get the average salary of employees in the company
    // todo: functionality that should be moved off-chain?
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

    // remove an employee (only callable by employer)
    function removeEmployee(address employeeAddress) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeAddress];
        require(
            existingEmployee.salary != 0,
            "Employee with the given address does not exist"
        ); // todo also handle a bit differently

        // remove the employee's salary details
        existingEmployee.title = "";
        existingEmployee.salary = 0;
        existingEmployee.salaryVerified = false;

        // Unlink the employee address from the addressToEmployeeId mapping
        addressToEmployeeId[employeeAddress] = 0;

        emit EmployeeUpdated(employeeAddress, "", 0);
    }

    // update an employee's details (only callable by employer)
    function updateEmployee(
        address employeeAddress,
        string memory title,
        uint256 salary
    ) external onlyEmployer {
        Employee storage existingEmployee = employees[employeeAddress];
        require(
            existingEmployee.salary != 0,
            "Employee with the given address does not exist"
        ); // todo

        existingEmployee.title = title;
        existingEmployee.salary = salary;
        // also resets the verified status of the salary to false since there might be changes.
        existingEmployee.salaryVerified = false;
        emit EmployeeUpdated(employeeAddress, title, salary);
    }

    // Function for an employee to verify their salary
    function verifySalary() external {
        address employeeAddress = msg.sender;
        Employee storage employee = employees[employeeAddress];
        // todo: change to a require that checks isEmployed[msg.sender]
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

    // todo remove?
    function getEmployeeAddresses() public view returns (address[] memory) {
        return employeeAddresses;
    }
}
