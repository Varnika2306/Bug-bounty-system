// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EduChain.sol";

/**
 * @title BugBounty
 * @dev Contract for managing bug bounties with educational integration
 */
contract BugBounty is Ownable, ReentrancyGuard {
    EduChain public eduChain;

    struct Bug {
        string title;
        string description;
        address reporter;
        uint256 bountyAmount;
        BugStatus status;
        uint256 submissionTime;
        uint256 resolutionTime;
        uint256 difficultyLevel;
        string[] requiredCertificates;
    }

    enum BugStatus { Open, UnderReview, Resolved, Rejected }

    mapping(uint256 => Bug) public bugs;
    mapping(address => uint256[]) public userSubmissions;
    mapping(address => uint256) public userReputation;
    
    uint256 private bugCounter;
    uint256 public minReputation;

    event BugSubmitted(uint256 indexed bugId, address indexed reporter, string title);
    event BugStatusUpdated(uint256 indexed bugId, BugStatus newStatus);
    event BountyPaid(uint256 indexed bugId, address indexed reporter, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    constructor(address _eduChainAddress) {
        eduChain = EduChain(_eduChainAddress);
        bugCounter = 0;
        minReputation = 0;
    }

    function submitBug(
        string memory _title,
        string memory _description,
        uint256 _difficultyLevel,
        string[] memory _requiredCertificates
    ) external payable returns (uint256) {
        require(msg.value > 0, "Bounty amount must be greater than 0");
        require(_difficultyLevel > 0 && _difficultyLevel <= 5, "Invalid difficulty level");
        
        // Verify user has required certificates
        if (_requiredCertificates.length > 0) {
            uint256[] memory userCerts = eduChain.getUserCertificates(msg.sender);
            require(userCerts.length > 0, "User must have required certificates");
        }

        bugCounter++;
        
        bugs[bugCounter] = Bug({
            title: _title,
            description: _description,
            reporter: msg.sender,
            bountyAmount: msg.value,
            status: BugStatus.Open,
            submissionTime: block.timestamp,
            resolutionTime: 0,
            difficultyLevel: _difficultyLevel,
            requiredCertificates: _requiredCertificates
        });

        userSubmissions[msg.sender].push(bugCounter);
        emit BugSubmitted(bugCounter, msg.sender, _title);
        
        return bugCounter;
    }

    function updateBugStatus(uint256 _bugId, BugStatus _newStatus) external onlyOwner {
        require(_bugId <= bugCounter, "Bug does not exist");
        require(_newStatus != bugs[_bugId].status, "Status is already set");

        bugs[_bugId].status = _newStatus;
        
        if (_newStatus == BugStatus.Resolved) {
            bugs[_bugId].resolutionTime = block.timestamp;
            _payBounty(_bugId);
            _updateReputation(bugs[_bugId].reporter, bugs[_bugId].difficultyLevel);
        }

        emit BugStatusUpdated(_bugId, _newStatus);
    }

    function _payBounty(uint256 _bugId) internal nonReentrant {
        Bug storage bug = bugs[_bugId];
        require(bug.bountyAmount > 0, "Bounty already paid");
        
        uint256 amount = bug.bountyAmount;
        bug.bountyAmount = 0;
        
        (bool success, ) = payable(bug.reporter).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit BountyPaid(_bugId, bug.reporter, amount);
    }

    function _updateReputation(address _user, uint256 _difficultyLevel) internal {
        uint256 reputationIncrease = _difficultyLevel * 10;
        userReputation[_user] += reputationIncrease;
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    function getUserBugs(address _user) external view returns (uint256[] memory) {
        return userSubmissions[_user];
    }

    function getBug(uint256 _bugId) external view returns (
        string memory title,
        string memory description,
        address reporter,
        uint256 bountyAmount,
        BugStatus status,
        uint256 submissionTime,
        uint256 resolutionTime,
        uint256 difficultyLevel,
        string[] memory requiredCertificates
    ) {
        Bug storage bug = bugs[_bugId];
        return (
            bug.title,
            bug.description,
            bug.reporter,
            bug.bountyAmount,
            bug.status,
            bug.submissionTime,
            bug.resolutionTime,
            bug.difficultyLevel,
            bug.requiredCertificates
        );
    }

    function setMinReputation(uint256 _minReputation) external onlyOwner {
        minReputation = _minReputation;
    }

    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }
}
