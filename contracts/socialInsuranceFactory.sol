// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./socialInsurance.sol";

contract SocialInsuranceFactory {
    // Mapping to store all SocialInsurance contracts created by each user
    mapping(address => address[]) public userContracts;
    uint256 public policyCount;
    address public socialInsuranceImp;

    // Event emitted when a new SocialInsurance contract is created
    event SocialInsuranceCreated(address indexed creator, address contractAddress, address policyHolder, address beneficiary);
   
    constructor(address _socialInsuranceImp) {
        socialInsuranceImp = _socialInsuranceImp;
    }

    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
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
        // Create a new SocialInsurance contract
        SocialInsurance newContract = SocialInsurance(clone(socialInsuranceImp));

        // Create the plan in the new contract
        newContract.initialize(
            _tokenAddress,
            _policyHolder,
            _socialId,
            _monthlyContribution,
            _daysUntilWithdrawal,
            _monthlyWithdrawal,
            _emergencyAddress
        );


        // Store the new contract address in the user's list
        userContracts[_policyHolder].push(address(newContract));

        if (_beneficiary != _policyHolder) {
            userContracts[_beneficiary].push(address(newContract));
        }

        if (_emergencyAddress != _policyHolder && _emergencyAddress != _beneficiary) {
            userContracts[_emergencyAddress].push(address(newContract));
        }
        policyCount++;

        // Emit an event
        emit SocialInsuranceCreated(msg.sender, address(newContract), _policyHolder, _beneficiary);

        return address(newContract);
    }

    // Function to get all contracts created by a user
    function getUserContracts(address user) public view returns (address[] memory) {
        return userContracts[user];
    }

    // Function to get the number of contracts created by a user
    function getUserContractCount(address user) public view returns (uint256) {
        return userContracts[user].length;
    }
}
