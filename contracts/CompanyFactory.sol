// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./Company.sol";

// todo fix sized arrays.
// todo

contract CompanyFactory {
    // variables and mappings
    address public owner;
    string[] public sectors; // todo add/remove functionality or not
    mapping(string => bool) public isSector; // todo change to sectors
    mapping(address => bool) public isRegistered;
    mapping(address => Company) public companies; // indexed by company id, id created when creating companu
    mapping(string => address[]) public companiesBySector; // maps a sector string to ids of companies in this sector.
    //mapping(string => address[]) public companiesBySize; // for example.. small, medium, large
    mapping(address => RegistryRight) public registry;

    struct RegistryRight {
        string companyName;
        string sector;
        bool granted;
        bool registered;
    }

    // events and modifiers
    event RegistryRightChanged(
        address companyKey,
        string companyName,
        string sector,
        bool granted
    );
    event CompanyAdded(
        address companyAdmin,
        address contractAddress,
        string companyName,
        string sector
    ); // todo add more interestig parameters

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // company registration and deletion

    function grantRegistryAccess(
        address companyKey,
        string memory _companyName,
        string memory _sector
    ) public onlyOwner {
        require(
            companyKey != address(0) &&
                bytes(_companyName).length > 0 &&
                bytes(_sector).length > 0,
            "Provide valid parameters for company registration."
        );
        require(
            !registry[companyKey].granted,
            "Access already granted for this key."
        );
        registry[companyKey] = RegistryRight({
            companyName: _companyName,
            sector: _sector,
            granted: true,
            registered: false
        });
        emit RegistryRightChanged(companyKey, _companyName, _sector, true);
    }

    function revokeRegistryAccess(address companyKey) public onlyOwner {
        RegistryRight storage r = registry[companyKey];
        require(r.granted == true, "No registry access for this key.");
        r.granted = false;
        emit RegistryRightChanged(companyKey, r.companyName, r.sector, false);
    }

    function createCompany() public {
        // conditions
        address companyKey = msg.sender; // todo
        RegistryRight storage r = registry[companyKey];
        require(
            registry[companyKey].granted,
            "This key has not been granted access for registration."
        );
        require(
            !isRegistered[companyKey],
            "Company already registered for this address."
        );
        r.registered = true;

        // create Company instance
        Company company = new Company(companyKey, r.companyName, r.sector); // ¿todo, más parametros? Soy le hombre de plastico, joder.
        companies[companyKey] = company;
        companiesBySector[r.sector].push(companyKey);
        emit CompanyAdded(
            companyKey,
            address(company),
            r.companyName,
            r.sector
        );
    }

    function removeCompany(address companyKey) public {
        address revoker = msg.sender;
        RegistryRight storage r = registry[revoker];
        require(r.registered, "No company registered for this key.");
        require(
            revoker == companies[companyKey].companyKey(), // todo, access right implementation instead.
            "You are not an admin at this company."
        );
        r.registered = false;
        address[] memory companiesInSector = companiesBySector[r.sector];
        // todo, might need to lock while removing.
        // todo: handle deletion from arrays other way?
        for (uint i = 0; i < companiesInSector.length; i++) {
            if (companiesInSector[i] == companyKey) {
                delete companiesInSector[i];
            }
        }
        companiesBySector[r.sector] = companiesInSector;
        // todo, think about logic for removing a contract, since the other instance still lives
        delete companies[companyKey]; // todo test this implementation
    }

    // query

    function getCompanyDetails(
        address companyKey
    )
        public
        view
        returns (
            string memory companyName,
            string memory sector,
            uint256 totalEmployees,
            uint256 averageSalary
        )
    {
        RegistryRight storage r = registry[companyKey];

        require(r.registered, "No company registered for this key.");
        Company company = companies[companyKey]; // todo: get methods for employees and sector
        totalEmployees = company.totalEmployees();
        averageSalary = company.getAverageSalary();
        return (r.companyName, r.sector, totalEmployees, averageSalary);
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
    // todo
    function getCompanyAddressesInSector(
        string memory sector
    ) public view returns (address[] memory) {
        require(isSector[sector], "Not a valid sector.");
        return companiesBySector[sector];
    }
}
