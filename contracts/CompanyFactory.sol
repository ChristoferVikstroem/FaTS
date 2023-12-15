// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Company.sol";

contract CompanyFactory {
    address public immutable owner;
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
        require(msg.sender == owner, "Not owner.");
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
        require(
            companyKey != address(0) &&
                bytes(_companyName).length > 0 &&
                bytes(_sector).length > 0,
            "Provide valid company data."
        );
        require(!registryRights[companyKey].granted, "Access already granted.");
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
        require(
            registryRights[companyKey].granted,
            "No registry access granted."
        );
        require(
            !registryRights[companyKey].registered,
            "Company already registered."
        );
        registryRights[companyKey].granted = false;
        emit RegistryRightChanged(
            companyKey,
            registryRights[companyKey].companyName,
            registryRights[companyKey].sector,
            registryRights[companyKey].granted,
            registryRights[companyKey].registered
        );
    }

    function registerCompany(address companyKey) public {
        require(
            registryRights[companyKey].granted,
            "No register access granted."
        );
        require(
            !registryRights[companyKey].registered,
            "Address already registered."
        );
        // register and revoke any rights to register again
        registryRights[companyKey].registered = true;
        registryRights[companyKey].granted = false;

        // create the Company contract
        Company company = new Company(
            companyKey,
            registryRights[companyKey].companyName,
            registryRights[companyKey].sector
        );

        // add to companies mapping and corresponding sector
        companies[companyKey] = company;
        companiesBySector[registryRights[companyKey].sector].push(companyKey);
        emit CompanyRegistered(
            companyKey,
            address(company),
            registryRights[companyKey].companyName,
            registryRights[companyKey].sector
        );
    }

    function removeCompany(address companyKey) public {
        require(
            registryRights[msg.sender].registered,
            "No company registered for key."
        );
        require(
            msg.sender == companies[companyKey].companyKey() ||
                msg.sender == owner,
            "Not authorized."
        );
        registryRights[msg.sender].registered = false;
        address[] storage companiesInSector = companiesBySector[
            registryRights[msg.sender].sector
        ];
        for (uint256 i = 0; i < companiesInSector.length; i++) {
            if (companiesInSector[i] == companyKey) {
                delete companiesInSector[i];
                break;
            }
        }
        emit CompanyRemoved(
            companyKey,
            registryRights[msg.sender].companyName,
            registryRights[msg.sender].sector
        );
        delete companies[companyKey];
        delete registryRights[companyKey];
    }

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
        require(
            registryRights[companyKey].registered,
            "No such company registered."
        );
        Company company = companies[companyKey];
        totalEmployees = company.totalEmployees();
        averageSalary = company.getAverageSalary();
        return (
            registryRights[companyKey].companyName,
            registryRights[companyKey].sector,
            totalEmployees,
            averageSalary
        );
    }

    function getCompanyAddressesInSector(
        string memory sector
    ) public view returns (address[] memory) {
        return companiesBySector[sector];
    }

    function getAverageSalaryInSector(
        string memory sector
    ) public view returns (uint256) {
        uint256 totalSalaries;
        uint256 totalEmployees;
        address[] memory c = companiesBySector[sector];
        for (uint256 i = 0; i < c.length; i++) {
            Company company = Company(c[i]);
            totalSalaries +=
                company.getAverageSalary() *
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
