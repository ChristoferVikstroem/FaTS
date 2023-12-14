// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/* todo: proper use of memory, calldata, storage
 * memory is used to store temporary data that is needed during the execution of a function.
 * calldata is used to store function arguments that are passed in from an external caller.
 * storage is used to store data permanently on the blockchain.
 */

// todo: more personal view?
// todo snapshot function

contract Company {
    // company details
    address public companyKey;
    string public sector; // final
    string public companyName;
    uint256 public totalEmployees;
    uint256 private totalSalaries;

    //address[] public employeeAddresses; // todo: remove? we have this info in the mapping
    mapping(address => Employee) public employees; // {address1: Employee object, address2: e}
    mapping(address => bool) public isEmployee; // todo better way to do this?

    struct Employee {
        string title;
        uint256 salary;
        bool salaryVerified;
    }

    // todo, make into one event?
    event EmployeeAdded(address employeeAddress, string title, uint256 salary);
    event EmployeeRemoved(
        address employeeAddress,
        string title,
        uint256 salary
    );
    event EmployeeUpdated(
        address employeeAddress,
        string oldTitle,
        string newTitle,
        uint256 oldSalary,
        uint256 newSalary
    );
    event SalaryVerified(address employeeAddress, uint256 salary);

    modifier onlyEmployer() {
        // todo: add functionality to add/remove employers/admins? and access control
        require(
            msg.sender == companyKey,
            "You are not an admin of this company."
        );
        _;
    }

    constructor(
        address _companyKey,
        string memory _companyName,
        string memory _sector
    ) {
        // todo any additional data we want to give a company?
        companyKey = _companyKey;
        companyName = _companyName;
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
        totalSalaries += _salary; // todo change?
        totalEmployees++; // change - this is the "length" of the mapping
        emit EmployeeAdded(employeeAddress, _title, _salary);
    }

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
        totalSalaries -= salary; // todo discuss if we should remove
        totalEmployees--;
        // remove employee
        delete employees[employeeAddress]; // test this
        emit EmployeeRemoved(employeeAddress, title, salary);
    }

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
        // todo use safemath
        totalSalaries -= oldSalary;
        totalSalaries += newSalary;
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
        // todo maybe have back for loop
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
