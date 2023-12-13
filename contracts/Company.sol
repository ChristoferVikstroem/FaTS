// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/* todo: proper use of memory, calldata, storage
 * memory is used to store temporary data that is needed during the execution of a function.
 * calldata is used to store function arguments that are passed in from an external caller.
 * storage is used to store data permanently on the blockchain.
 */

contract Company {
    // company details
    address public employer; // todo decide on name: employer or companyAdmin, use same in both contracts.
    string public sector; // final
    uint256 public totalEmployees;
    uint256 private totalSalaries;

    address[] public employeeAddresses; // todo: remove? we have this info in the mapping
    mapping(address => Employee) public employees;
    mapping(address => bool) private isEmployee;

    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    event EmployeeAdded(address employeeAddress, string title, uint256 salary);
    event EmployeeRemoved(
        address employeeAddress,
        string title,
        uint256 salary
    );
    event SalaryVerified(address employeeAddress, uint256 salary);
    event EmployeeUpdated(
        address employeeAddress,
        string oldTitle,
        string newTitle,
        uint256 oldSalary,
        uint256 newSalary
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
        string memory _title,
        uint256 _salary
    ) external onlyEmployer {
        require(
            !isEmployee[employeeAddress],
            "Address already registered as employee."
        );
        isEmployee[employeeAddress] = true;
        // todo lock.
        employees[employeeAddress] = Employee({
            title: _title,
            salary: _salary,
            salaryVerified: false
        });
        totalSalaries += _salary;
        totalEmployees++;
        emit EmployeeAdded(employeeAddress, _title, _salary);
    }

    // remove an employee (only callable by employer)
    function removeEmployee(address employeeAddress) external onlyEmployer {
        require(
            isEmployee[employeeAddress],
            "Address not a registered emplooyee."
        );
        isEmployee[employeeAddress] = false;
        // remove global employee data
        Employee memory employee = employees[employeeAddress];
        string memory title = employee.title;
        uint256 salary = employee.salary;
        totalSalaries -= salary;
        totalEmployees--;
        // remove employee
        delete employees[employeeAddress]; // test this
        emit EmployeeRemoved(employeeAddress, title, salary);
    }

    // update an employee's details (only callable by employer)
    function updateEmployee(
        address employeeAddress,
        string memory newTitle,
        uint256 newSalary
    ) external onlyEmployer {
        require(
            isEmployee[employeeAddress],
            "Address not a registered emplooyee."
        );
        // remove global data
        // todo lock
        Employee memory employee = employees[employeeAddress];
        string memory oldTitle = employee.title;
        uint256 oldSalary = employee.salary;
        employee.salaryVerified = false;
        employee.salary = newSalary;
        employee.title = newTitle;
        totalSalaries += (newSalary - oldSalary);
        emit EmployeeUpdated(
            employeeAddress,
            oldTitle,
            newTitle,
            oldSalary,
            newSalary
        );
    }

    // get the average salary of employees in the company
    // todo: functionality that should be moved off-chain?
    function getAverageSalary() external view returns (uint256) {
        if (totalEmployees > 0) {
            return totalSalaries / totalEmployees;
        } else {
            return 0;
        }
    }

    // Function for an employee to verify their salary
    function verifySalary() external {
        address employeeAddress = msg.sender;
        require(
            isEmployee[employeeAddress],
            "Address not registered as employee."
        );
        Employee storage employee = employees[employeeAddress];
        require(
            !employee.salaryVerified,
            "Salary already verified for this employee."
        );
        employee.salaryVerified = true;
        emit SalaryVerified(employeeAddress, employee.salary);
    }
}
