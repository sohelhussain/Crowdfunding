// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState { Active, Successful, Failed }
    CampaignState public state;



    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer {
        uint256 totalContribution;
        mapping (uint256 => bool) fundedTiers;
    }


    Tier[] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not a owner");
        _;
    }

    modifier campaignOpen() {
            require(state == CampaignState.Active, "Campaign is not open.");
            _;
        }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor (string memory _name, string memory _description, uint256 _goal, uint256 _durationInDays, address _owner){
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        owner = _owner;
        state = CampaignState.Active;
    }

    function checkAndCampaignState() internal {
        if(state == CampaignState.Active){
            if(block.timestamp >= deadline){
            state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }else {
            state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
        }
        }
    }
    function fund(uint256 _tierIndex) public payable campaignOpen notPaused {
        require(_tierIndex < tiers.length, "Invalid tier");
        require(msg.value == tiers[_tierIndex].amount, "Invalid amount");

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierIndex] = true;
        checkAndCampaignState();
    }

    function addTier(string memory _name, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount cannot be zero or negative.");
        tiers.push(Tier(_name, _amount, 0));
    }

    function removeTier(uint256 _index) public onlyOwner {
        require(_index < tiers.length, "Tier dose not exist");
        tiers[_index] = tiers[tiers.length - 1];
        tiers.pop();
    }
    function withdraw() public onlyOwner {
        checkAndCampaignState();
        require(state == CampaignState.Successful, "Campaing Not Successful");

        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(owner).transfer(balance);
    }

    function gegtContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public {
        checkAndCampaignState();
        require(state == CampaignState.Successful, "No refund for failed camp");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "Refund not possible.");
        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hashFundedTier(address _backer, uint256 _tierIndex) public view returns (bool){
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function getTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline){
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Successful;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += (_daysToAdd * 1 days);
    }
}