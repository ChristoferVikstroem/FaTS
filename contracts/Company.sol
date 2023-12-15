// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Company {
    // company details
    address public companyKey;
    string public sector;
    string public companyName;
    uint256 public totalEmployees;
    uint256 private totalSalaries;
    mapping(address => Employee) public employees;

    // gender, yrs experience, update or calculate.
    enum Gender {
        Female,
        Male,
        Other
    }

    struct Employee {
        string title;
        Gender gender;
        uint256 salary;
        uint32 yearsPriorExperience;
        uint256 dateEmployed;
        bool isEmployee;
        bool salaryVerified;
    }

    event EmployeeAdded(
        address employeeAddress,
        string title,
        Gender gender,
        uint256 salary,
        uint32 yearsOfExperience
    );

    event EmployeeRemoved(
        address employeeAddress,
        string title,
        Gender gender,
        uint256 salary,
        uint32 yearsPriorExperience,
        uint256 dateEmployed
    );
    event EmployeeUpdated(
        address employeeAddress,
        string oldTitle,
        string newTitle,
        uint256 oldSalary,
        uint256 newSalary,
        Gender oldGender,
        Gender newGender
    );

    event SalaryVerified(
        address employeeAddress,
        string title,
        Gender gender,
        uint256 salary
    );

    modifier onlyEmployer() {
        // todo: add access control library?
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

    function addEmployee(
        address employeeAddress,
        string memory _title,
        Gender _gender,
        uint32 _yearsPriorExperience,
        uint256 _salary
    ) external onlyEmployer {
        require(
            !employees[employeeAddress].isEmployee,
            "Already registered employee."
        );
        require(
            employeeAddress != address(0) && bytes(_title).length > 0,
            "Provide valid employee data."
        );
        employees[employeeAddress] = Employee({
            title: _title,
            salary: _salary,
            gender: _gender,
            yearsPriorExperience: _yearsPriorExperience,
            dateEmployed: block.timestamp,
            salaryVerified: false,
            isEmployee: true
        });
        totalSalaries = totalSalaries + _salary;
        totalEmployees = totalEmployees + 1;
        emit EmployeeAdded(
            employeeAddress,
            _title,
            _gender,
            _salary,
            _yearsPriorExperience
        );
    }

    function removeEmployee(address employeeAddress) external onlyEmployer {
        require(
            employees[employeeAddress].isEmployee,
            "Not a registered employee."
        );
        Employee memory removedEmployee = employees[employeeAddress];
        employees[employeeAddress].isEmployee = false;
        totalSalaries = totalSalaries - removedEmployee.salary;
        totalEmployees = totalEmployees - 1;
        emit EmployeeRemoved(
            employeeAddress,
            removedEmployee.title,
            removedEmployee.gender,
            removedEmployee.salary,
            removedEmployee.yearsPriorExperience,
            removedEmployee.dateEmployed
        );
        delete employees[employeeAddress];
    }

    // todo, update years experience?
    function updateEmployee(
        address employeeAddress,
        string memory newTitle,
        Gender newGender,
        uint256 newSalary
    ) external onlyEmployer {
        require(
            employees[employeeAddress].isEmployee,
            "Not a registered employee."
        );
        require(bytes(newTitle).length > 0, "Provide valid employee data.");

        Employee memory oldEmployee = employees[employeeAddress];
        employees[employeeAddress].salaryVerified = false;
        employees[employeeAddress].salary = newSalary;
        employees[employeeAddress].title = newTitle;
        totalSalaries = totalSalaries - oldEmployee.salary;
        totalSalaries = totalSalaries + newSalary;

        emit EmployeeUpdated(
            employeeAddress,
            oldEmployee.title,
            newTitle,
            oldEmployee.salary,
            newSalary,
            oldEmployee.gender,
            newGender
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

    function getSalary(
        address employeeAddress
    ) public view returns (string memory title, uint256 salary, bool verified) {
        require(
            employees[employeeAddress].isEmployee,
            "Not a registered employee."
        );
        return (
            employees[employeeAddress].title,
            employees[employeeAddress].salary,
            employees[employeeAddress].salaryVerified
        );
    }

    function verifySalary() external {
        /* lets an employee verify their own salary */
        require(employees[msg.sender].isEmployee, "Not a registered employee.");
        require(
            !employees[msg.sender].salaryVerified,
            "Salary already verified."
        );
        employees[msg.sender].salaryVerified = true;
        emit SalaryVerified(
            msg.sender,
            employees[msg.sender].title,
            employees[msg.sender].gender,
            employees[msg.sender].salary
        );
    }
}
