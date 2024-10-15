   // SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

   contract SocialInsurance {
        IERC20 public depositedToken;

        uint256 public monthlyContribution;
        uint256 public daysUntilWithdrawal;
        uint256 public monthlyWithdrawal;
        address public emergencyAddress;
        address public policyHolder;
        address public beneficiary;
        uint256 public socialId;
        uint256 public initialTime;
        uint256 public lastWithdrawalTime;
        bool public isContractActive;
        bool public bInitialized;

        // Add this modifier
        modifier onlyActive() {
            require(isContractActive, "Contract is no longer active");
            _;
        }
    
        constructor() {   
            bInitialized = true;         
        }

        // Add these event declarations near the top of your contract
        event PlanCreated(address indexed policyHolder, uint256 socialId, uint256 monthlyContribution, uint256 daysUntilWithdrawal, uint256 monthlyWithdrawal, address emergencyAddress);
        event Claim(address indexed beneficiary, uint256 socialId, uint256 amount);
        event UnpaidFundsWithdrawal(address indexed policyHolder, uint256 amount);
        event EmergencyWithdrawal(address indexed initiator, address indexed recipient, uint256 amount);

        function initialize(
            address _tokenAddress,
            address _policyHolder,
            uint256 _socialId,
            uint256 _monthlyContribution,
            uint256 _daysUntilWithdrawal,
            uint256 _monthlyWithdrawal,
            address _emergencyAddress
        ) public {
            require(!bInitialized, "!initialized.");
            bInitialized = true;  
            isContractActive = true;

            depositedToken = IERC20(_tokenAddress);
            policyHolder = _policyHolder;
            socialId = _socialId;
            monthlyContribution = _monthlyContribution;
            daysUntilWithdrawal = _daysUntilWithdrawal;
            monthlyWithdrawal = _monthlyWithdrawal;
            emergencyAddress = _emergencyAddress;

            initialTime = block.timestamp;
            lastWithdrawalTime = initialTime + (daysUntilWithdrawal * 1 days);

            emit PlanCreated(_policyHolder, _socialId, _monthlyContribution, _daysUntilWithdrawal, _monthlyWithdrawal, _emergencyAddress);
        }

        function isWithdrawable() public view returns(bool) {
            return block.timestamp >= initialTime + (daysUntilWithdrawal * 1 days);
        }

        function withdrawUnpaidFunds() public {
            require(msg.sender == policyHolder, "Only policyHolder can withdraw.");

            uint256 amount = withdrawableBalance();

            require(depositedToken.transfer(policyHolder, amount), "Token transfer failed");

            emit UnpaidFundsWithdrawal(policyHolder, amount);
        }

        function withdrawableBalance() public view returns(uint256) {
            return depositedToken.balanceOf(address(this)) - totalPaid();
        }

        function totalPaid() public view returns(uint256) {
            uint256 monthsPassed = (block.timestamp - initialTime) / 30 days;
            return monthsPassed * monthlyContribution;
        }

        function claim(bytes calldata _proof) public onlyActive {
            require(
                verifier.verifyProof(
                    _proof,
                    [socialId]
                ),
                "Invalid withdraw proof"
            );
            
            address beneficiary = msg.sender;
            uint256 amountToWithdraw = calculateWithdrawableAmount();
            require(amountToWithdraw > 0, "No funds available for withdrawal");

            require(depositedToken.balanceOf(address(this)) >= amountToWithdraw, "Insufficient tokens in contract");
            require(depositedToken.transfer(beneficiary, amountToWithdraw), "Token transfer failed");

            lastWithdrawalTime = block.timestamp;

            emit Claim(beneficiary, socialId, amountToWithdraw);
        }

        function calculateWithdrawableAmount() public view returns (uint256) {
            uint256 startWithdrawTime = initialTime + (daysUntilWithdrawal * 1 days);
            if (block.timestamp < startWithdrawTime) {
                return 0; // Withdrawal period has not started yet
            }

            uint256 monthsSinceWithdrawalStart = (block.timestamp - startWithdrawTime) / 30 days;
            uint256 monthsSinceLastWithdrawal = (lastWithdrawalTime - startWithdrawTime) / 30 days;
            uint256 theoreticalWithdrawAmount = (monthsSinceWithdrawalStart - monthsSinceLastWithdrawal) * monthlyWithdrawal;

            uint256 availableBalance = depositedToken.balanceOf(address(this));

            return theoreticalWithdrawAmount > availableBalance ? availableBalance : theoreticalWithdrawAmount;
        }

        function emergencyWithdraw() public onlyActive {
            require(msg.sender == policyHolder || msg.sender == emergencyAddress, "Only policy holder or emergency address can initiate emergency withdrawal");

            uint256 balance;
            balance = depositedToken.balanceOf(address(this));

            if (balance > 0) {
                require(depositedToken.transfer(beneficiary, balance), "Token transfer failed");
                lastWithdrawalTime = block.timestamp;
            }

            isContractActive = false;

            emit EmergencyWithdrawal(msg.sender, beneficiary, balance);
        }
   }