// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/* todo: proper use of memory, calldata, storage
 * memory is used to store temporary data that is needed during the execution of a function.
 * calldata is used to store function arguments that are passed in from an external caller.
 * storage is used to store data permanently on the blockchain.
 */

// todo snapshot function

contract Company {
    // company details
    address public companyKey;
    string public sector;
    string public companyName;
    uint256 public totalEmployees;
    uint256 private totalSalaries;
    mapping(address => Employee) public employees; // {address1: Employee object, address2: e}

    struct Employee {
        string title;
        uint256 salary;
        bool isEmployee; // todo
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
    event SalaryVerified(address employeeAddress, string title, uint256 salary);

    modifier onlyEmployer() {
        // todo: add functionality to add/remove employers/admins? and access control
        require(msg.sender == companyKey, "You are not a company admin.");
        _;
    }

    constructor(
        address _companyKey,
        string memory _companyName,
        string memory _sector
    ) {
        // require input validation
        companyKey = _companyKey;
        companyName = _companyName;
        sector = _sector;
    }

    // employee functionalitypul

    function addEmployee(
        address employeeAddress,
        string memory _title,
        uint256 _salary
    ) external onlyEmployer {
        Employee storage e = employees[employeeAddress];
        require(!e.isEmployee, "Already registered employee.");
        require(
            employeeAddress != address(0) && bytes(_title).length > 0,
            "Provide valid employee data."
        );
        e.isEmployee = true;

        // todo lock?
        employees[employeeAddress] = Employee({
            title: _title,
            salary: _salary,
            salaryVerified: false,
            isEmployee: true
        });
        totalSalaries = totalSalaries + _salary;
        totalEmployees = totalEmployees + 1;
        emit EmployeeAdded(employeeAddress, _title, _salary);
    }

    function removeEmployee(address employeeAddress) external onlyEmployer {
        Employee storage e = employees[employeeAddress];
        require(e.isEmployee, "Not a registered employee.");
        e.isEmployee = false;
        // remove global employee data
        string memory title = e.title;
        uint256 salary = e.salary;
        totalSalaries = totalSalaries - salary;
        totalEmployees = totalEmployees - 1;
        // remove employee
        delete employees[employeeAddress]; // test this
        emit EmployeeRemoved(employeeAddress, title, salary);
    }

    function updateEmployee(
        address employeeAddress,
        string memory newTitle,
        uint256 newSalary
    ) external onlyEmployer {
        Employee storage e = employees[employeeAddress];
        require(e.isEmployee, "Not a registered employee.");
        require(bytes(newTitle).length > 0, "Provide valid employee data.");
        // remove global data
        // todo lock?
        string memory oldTitle = e.title;
        uint256 oldSalary = e.salary;
        e.salaryVerified = false;
        e.salary = newSalary;
        e.title = newTitle;
        totalSalaries = totalSalaries - oldSalary;
        totalSalaries = totalSalaries + newSalary;
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
        if (totalEmployees >= 1) {
            return totalSalaries / totalEmployees;
        } else {
            return 0;
        }
    }

    function getSalary(
        address employeeAddress
    ) public view returns (string memory title, uint256 salary, bool verified) {
        Employee storage e = employees[employeeAddress];
        require(e.isEmployee, "Not a registered employee.");
        return (e.title, e.salary, e.salaryVerified);
    }

    // Function for an employee to verify their salary
    function verifySalary() external {
        address employeeAddress = msg.sender;
        Employee storage e = employees[employeeAddress];
        require(e.isEmployee, "Not a registered employee.");
        require(!e.salaryVerified, "Salary already verified.");
        e.salaryVerified = true;
        emit SalaryVerified(employeeAddress, e.title, e.salary);
    }
}
