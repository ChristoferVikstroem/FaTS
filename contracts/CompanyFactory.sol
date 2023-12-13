// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./Company.sol";

// todo fix sized arrays.
// todo

contract CompanyFactory {
    // variables and mappings
    address _owner;
    string[] public sectors; // todo add/remove functionality or not
    mapping(string => bool) public isSector; // todo change to sectors
    mapping(address => bool) public isRegistered;
    mapping(address => Company) public companies; // indexed by company id, id created when creating companu
    mapping(string => address[]) public companiesBySector; // maps a sector string to ids of companies in this sector.
    //mapping(string => address[]) public companiesBySize; // for example.. small, medium, large

    // events and modifiers
    event CompanyAdded(address companyAddress, string sector); // todo add more interestig parameters
    event SectorAdded(string sector);
    event SectorRemoved(string sector);
    // todo any other relevant events

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner.");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    // company registration and deletion

    function createCompany(
        string memory sector,
        string memory adminTitle,
        uint256 adminSalary
    ) public {
        // conditions
        address companyAdmin = msg.sender;
        require(
            !isRegistered[companyAdmin],
            "Company already registered for this address."
        );
        require(
            bytes(adminTitle).length > 0 && (adminSalary > 0),
            "Company admin's title and salary must be submitted."
        );
        require(isSector[sector], "Company is not a valid sector.");
        isRegistered[companyAdmin] = true;

        // create Company instance
        Company company = new Company(companyAdmin, sector); // ¿todo, más parametros? Soy le hombre de plastico, joder.
        companies[companyAdmin] = company;
        companiesBySector[sector].push(companyAdmin);
        company.addEmployee(msg.sender, adminTitle, adminSalary);
        emit CompanyAdded(address(company), sector);
    }

    function removeCompany(address companyAddress) public {
        address companyAdmin = msg.sender;
        require(
            isRegistered[companyAdmin],
            "No company registered under this address."
        );
        require(
            companyAdmin == companies[companyAddress].employer(),
            "You are not an admin at this company."
        );

        isRegistered[companyAdmin] = false;
        string memory companySector = companies[companyAdmin].sector();
        address[] memory companiesInSector = companiesBySector[companySector];
        // todo, might need to lock while removing.
        // todo: handle deletion from arrays other way?
        for (uint i = 0; i < companiesInSector.length; i++) {
            if (companiesInSector[i] == companyAdmin) {
                delete companiesInSector[i];
            }
        }
        companiesBySector[companySector] = companiesInSector;
        // todo, think about logic for removing a contract, since the other instance still lives
        delete companies[companyAdmin]; // todo test this implementation
    }

    // query

    function getCompanyDetails(
        address companyAddress
    )
        public
        view
        returns (
            string memory sector,
            uint256 totalEmployees,
            uint256 averageSalary
        )
    {
        require(
            isRegistered[companyAddress],
            "No company registered at this address."
        );
        Company company = companies[companyAddress]; // todo: get methods for employees and sector
        totalEmployees = company.totalEmployees();
        averageSalary = company.getAverageSalary();
        sector = company.sector();
        return (sector, totalEmployees, averageSalary);
    }

    // function to get the average salary of employees in a sector
    /*  todo: this processing should perhaps be done in a front end. 
             and the function just returns _data_ about the sector.
        todo: what is reasonable to query for a sector? what should be returned. */
    function getAverageSalaryInSector(
        string memory sector
    ) public view returns (uint256) {
        require(isSector[sector], "Not a valid sector.");
        uint256 totalSalaries;
        uint256 totalEmployees;

        for (uint256 i = 0; i < companiesBySector[sector].length; i++) {
            Company company = Company(companiesBySector[sector][i]);
            totalSalaries +=
                company.getAverageSalary() *
                company.totalEmployees();
            totalEmployees += company.totalEmployees();
        }

        if (totalEmployees > 0) {
            return totalSalaries / totalEmployees;
        } else {
            return 0;
        }
    }

    // Function to get the addresses of companies in a sector
    function getCompanyAddressesInSector(
        string memory sector
    ) public view returns (address[] memory) {
        require(isSector[sector], "Not a valid sector.");
        return companiesBySector[sector];
    }
}
