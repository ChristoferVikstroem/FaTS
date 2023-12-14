// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./Company.sol";

// todo fix sized arrays.

contract CompanyFactory {
    // variables and mappings
    address public owner;
    mapping(address => Company) public companies; // indexed by company id, id created when creating companu
    mapping(string => address[]) public companiesBySector; // maps a sector string to ids of companies in this sector.
    //mapping(string => address[]) public companiesBySize; // for example.. small, medium, large
    mapping(address => RegistryRight) public registryRights;
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
        bool granted,
        bool registered
    );
    event CompanyRegistered(
        address companyKey,
        address contractAddress,
        string companyName,
        string sector
    );
    event CompanyRemoved(address companyKey, string companyName, string sector);
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() payable {
        owner = msg.sender;
    }

    // company registration and deletion

    function grantRegistryRight(
        address companyKey,
        string memory _companyName,
        string memory _sector
    ) public onlyOwner {
        RegistryRight storage r = registryRights[companyKey];
        require(
            companyKey != address(0) &&
                bytes(_companyName).length > 0 &&
                bytes(_sector).length > 0,
            "Provide valid company data."
        );
        require(!r.granted, "Access already granted.");
        registryRights[companyKey] = RegistryRight({
            companyName: _companyName,
            sector: _sector,
            granted: true,
            registered: false
        });
        emit RegistryRightChanged(
            companyKey,
            _companyName,
            _sector,
            true,
            false
        );
    }

    function revokeRegistryRight(address companyKey) public onlyOwner {
        RegistryRight storage r = registryRights[companyKey];
        require(r.granted, "No registry access granted.");
        require(!r.registered, "Company already registered.");
        r.granted = false;
        emit RegistryRightChanged(
            companyKey,
            r.companyName,
            r.sector,
            r.granted,
            r.registered
        );
    }

    function registerCompany(address companyKey) public {
        RegistryRight storage r = registryRights[companyKey];
        require(r.granted, "No register acccess granted.");
        require(!r.registered, "Address already registered.");
        r.registered = true;
        r.granted = false; // reset grant

        // create Company instance using granted name and sector
        Company company = new Company(companyKey, r.companyName, r.sector);
        companies[companyKey] = company;
        companiesBySector[r.sector].push(companyKey);
        emit CompanyRegistered(
            companyKey,
            address(company),
            r.companyName,
            r.sector
        );
    }

    function removeCompany(address companyKey) public {
        address revoker = msg.sender;
        RegistryRight storage r = registryRights[revoker];
        require(r.registered, "No company registered for key.");
        require(
            (revoker == companies[companyKey].companyKey() || revoker == owner), // todo, access right implementation instead.
            "Not authorized."
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
        delete companies[companyKey];
        emit CompanyRemoved(companyKey, r.companyName, r.sector);
        delete registryRights[companyKey];
    }

    // query
    // todo: should we even have average salary functionality here? or is that rather processed in a front end.

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
        RegistryRight storage r = registryRights[companyKey];
        require(r.registered, "No such company registered.");
        Company company = companies[companyKey];
        totalEmployees = company.totalEmployees();
        averageSalary = company.getAverageSalary();
        return (r.companyName, r.sector, totalEmployees, averageSalary);
    }

    function getCompanyAddressesInSector(
        string memory sector
    ) public view returns (address[] memory) {
        return companiesBySector[sector];
    }

    // function to get the average salary of employees in a sector
    /*  todo: this processing should perhaps be done in a front end. 
             and the function just returns _data_ about the sector.
        todo: what is reasonable to query for a sector? what should be returned. */
    function getAverageSalaryInSector(
        string memory sector
    ) public view returns (uint256) {
        uint256 totalSalaries;
        uint256 totalEmployees;

        for (uint256 i = 0; i < companiesBySector[sector].length; i++) {
            Company company = Company(companiesBySector[sector][i]);
            totalSalaries +=
                company.getAverageSalary() *
                company.totalEmployees();
            totalEmployees += company.totalEmployees();
        }

        if (totalEmployees >= 1) {
            return totalSalaries / totalEmployees;
        } else {
            return 0;
        }
    }
}
