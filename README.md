# Fair and Transparent Salaries (FaTS)
FaTS is an open-source repository for a smart contract development in the KTH course DD2485. The protocol utilizes blockchain technology to make salary information more visible (transparent).
The protocol are written in Solidity and contains two contracts: CompanyFactory.sol and Company.sol
## Motivation and Background
 The motivation behind this development is to allow employees to gain more information about the salaries of their peers in the company they are employed at, specific salary details of connected companies, and the average salary of employees within specific sectors. There are existing initiatives for making salary information more public, transparent and available (e.g., glassdoor https://www.glassdoor.com/) but the goal here is to motivate companies (employers) to deploy FaTS as a way to be transparent about their salaries. Specific employee information is anonymized besides their employment title and their salary. To increase trust, each employee can verify that their reported salary is correct. By putting this on the blockchain, nothing will be hidden, meaning that changes within an organization (layoffs or salary changes) will be visible for everyone. The protocol aims to give employees more information when negotiating their compensation and to create more trust for specific organizations by holding them more accountable.

## CompanyFactory.sol

### Features
- Users can register a new company within a specified sector.
- The contract ensures unique company registration per cryptographic identity (e.g. digital wallet address).
- Companies can be removed by their administrators.

**Sector Management**
- Sectors are defined as string identifiers.
- Users can add and remove sectors dynamically.

**Event Logging**

- Events are emitted to log significant contract activities, such as adding companies and modifying sectors.

**Query Functions**
- Retrieve details about a specific company, including its sector, total employees, and average salary.
- Obtain the average salary within a specific sector.
- Get the addresses of companies within a given sector.

### Usage (CompanyFactory.sol)

**Deployment** 
- Deploy the CompanyFactory smart contract to the Sepolia blockchain.

**Company Registration**

1. Call the createCompany function to register a new company within a specific sector.
2. Provide the sector name, admin title, and admin salary.

**Company Deletion**

1. Use the removeCompany function to delete a registered company.
Only administrators of the company can initiate this operation.

**Query Functions**

- Retrieve company details using getCompanyDetails.
- Calculate the average salary in a sector with getAverageSalaryInSector.
- Obtain addresses of companies within a sector using getCompanyAddressesInSector.

**Sector Management**
- Dynamically add sectors with the addSector function.
- Remove sectors with the removeSector function.


### Events
- CompanyAdded: Logged when a new company is successfully registered.
- SectorAdded: Logged when a new sector is added.
- SectorRemoved: Logged when a sector is removed.

## Company.sol

### Features
**Employee Management**
- Employers can add new employees to the company, specifying their title and salary.
- Registered employees can be removed from the company by the employer.
- Employers can update the title and salary of existing employees.

**Employee Verification**
- Employees can verify their own salary, providing transparency and accountability.

**Average Salary Calculation**
- The contract provides a function to calculate the average salary of all employees within the company.

**Events**
- Events are emitted for significant activities, such as adding, removing, updating employees, and verifying salaries.

**Access Control**
- The contract includes access control to ensure that only the employer/administrator can perform certain operations.

### Usage (Company.sol)
**Deployment**
- Deploy the EmployeeManagement smart contract after deploying the CompanyFactory contract.
- CompanyFactory.sol will give a specific address for the created company's contract.

**Employee Management**

- Use the addEmployee function to register a new employee, providing their address, title, and salary.
- Remove existing employees with the removeEmployee function.
- Update employee details with the updateEmployee function.

**Verification**

- Employees can verify their own salary using the verifySalary function.

**Average Salary**

- Retrieve the average salary of all employees in the company using the getAverageSalary function.

### Events
- EmployeeAdded: Logged when a new employee is successfully added.
- EmployeeRemoved: Logged when an employee is removed from the company.
- EmployeeUpdated: Logged when an employee's details are updated.
- SalaryVerified: Logged when an employee verifies their salary.

### Access Control
- The onlyEmployer modifier ensures that only the employer/administrator can execute certain functions.
