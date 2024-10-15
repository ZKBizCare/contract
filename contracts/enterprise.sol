// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./socialInsuranceFactory.sol";

contract Enterprise {
    struct EnterpriseInfo {
        uint256 id;
        string name; 
        string location; 
        string introduce;
        address owner;
    }

    SocialInsuranceFactory public socialInsuranceFactory;
    EnterpriseInfo[] public enterpriseList;
    mapping(address => uint256[]) public ownerEnterpriseList;

    constructor(SocialInsuranceFactory _socialInsuranceFactory) {  
        socialInsuranceFactory = _socialInsuranceFactory;        
    }

    function register(string memory name, string memory location, string memory introduce) public returns(uint256) {
        enterpriseList.push({
            id: enterpriseList.length + 1,
            name, 
            location, 
            introduce,
            owner: msg.sender
        })

        ownerEnterpriseList[msg.sender].push(enterpriseList.length);

        return enterpriseList.length;
    }

    function createSocialInsurance(
        address _tokenAddress,
        address _policyHolder,
        uint256 _socialId,
        uint256 _monthlyContribution,
        uint256 _daysUntilWithdrawal,
        uint256 _monthlyWithdrawal,
        address _emergencyAddress
    ) public returns (address) {
        return socialInsuranceFactory.createSocialInsurance(_tokenAddress,
                                                     _policyHolder, 
                                                     _socialId, 
                                                     _monthlyContribution,
                                                     _daysUntilWithdrawal,
                                                     _monthlyWithdrawal,
                                                     _emergencyAddress);
    }
}