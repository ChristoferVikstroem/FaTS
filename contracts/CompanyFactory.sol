// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./Company.sol";

contract CompanyFactory {
    address public owner;
    mapping(address => Company) public companies;
    mapping(string => address[]) public companiesBySector;
    mapping(address => RegistryRight) public registryRights;

    struct RegistryRight {
        string companyName;
        string sector;
        bool granted;
        bool registered;
    }

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
        require(msg.sender == _owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

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
        require(r.granted, "No register access granted.");
        require(!r.registered, "Address already registered.");
        r.registered = true;
        r.granted = false;

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
            revoker == companies[companyKey].companyKey() || revoker == owner,
            "Not authorized."
        );
        r.registered = false;
        address[] storage companiesInSector = companiesBySector[r.sector];
        for (uint256 i = 0; i < companiesInSector.length; i++) {
            if (companiesInSector[i] == companyKey) {
                delete companiesInSector[i];
                break;
            }
        }
        emit CompanyRemoved(companyKey, r.companyName, r.sector);
        delete companies[companyKey];
        delete registryRights[companyKey];
    }

    function getCompanyDetails(address companyKey)
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

    function getCompanyAddressesInSector(string memory sector)
        public
        view
        returns (address[] memory)
    {
        return companiesBySector[sector];
    }

    function getAverageSalaryInSector(string memory sector)
        public
        view
        returns (uint256)
    {
        uint256 totalSalaries;
        uint256 totalEmployees;
        address[] memory c = companiesBySector[sector];
        for (uint256 i = 0; i < c.length; i++) {
            Company company = Company(c[i]);
            totalSalaries += company.getAverageSalary() *
                company.totalEmployees();
            totalEmployees += company.totalEmployees();
            }
        if (totalEmployees > 0) {
            uint256 average = totalSalaries / totalEmployees;
            return average;
        } else {
            return 0;
        }
    }
}
