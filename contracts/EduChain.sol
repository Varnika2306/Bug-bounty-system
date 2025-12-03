// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title EduChain
 * @dev Contract for managing educational content and certifications in the bug bounty platform
 */
contract EduChain is Ownable, ERC721 {
    uint256 private _certificateIds;

    struct Course {
        string title;
        string description;
        string contentURI;
        uint256 difficulty;
        bool isActive;
        address instructor;
    }

    struct Certificate {
        uint256 courseId;
        address recipient;
        uint256 timestamp;
        uint256 score;
    }

    mapping(uint256 => Course) public courses;
    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public userCertificates;
    
    uint256 private courseCounter;

    event CourseCreated(uint256 indexed courseId, string title, address instructor);
    event CertificateIssued(uint256 indexed certificateId, address indexed recipient, uint256 courseId);
    event CourseCompleted(address indexed user, uint256 indexed courseId, uint256 score);

    constructor() ERC721("EduChain Certificate", "EDC") {
        courseCounter = 0;
        _certificateIds = 0;
    }

    function createCourse(
        string memory _title,
        string memory _description,
        string memory _contentURI,
        uint256 _difficulty
    ) external returns (uint256) {
        courseCounter++;
        
        courses[courseCounter] = Course({
            title: _title,
            description: _description,
            contentURI: _contentURI,
            difficulty: _difficulty,
            isActive: true,
            instructor: msg.sender
        });

        emit CourseCreated(courseCounter, _title, msg.sender);
        return courseCounter;
    }

    function issueCertificate(address _recipient, uint256 _courseId, uint256 _score) external {
        require(courses[_courseId].isActive, "Course does not exist or is inactive");
        require(_score <= 100, "Score must be between 0 and 100");

        _certificateIds++;
        uint256 newCertificateId = _certificateIds;

        certificates[newCertificateId] = Certificate({
            courseId: _courseId,
            recipient: _recipient,
            timestamp: block.timestamp,
            score: _score
        });

        userCertificates[_recipient].push(newCertificateId);
        _safeMint(_recipient, newCertificateId);

        emit CertificateIssued(newCertificateId, _recipient, _courseId);
        emit CourseCompleted(_recipient, _courseId, _score);
    }

    function getCourse(uint256 _courseId) external view returns (
        string memory title,
        string memory description,
        string memory contentURI,
        uint256 difficulty,
        bool isActive,
        address instructor
    ) {
        Course memory course = courses[_courseId];
        return (
            course.title,
            course.description,
            course.contentURI,
            course.difficulty,
            course.isActive,
            course.instructor
        );
    }

    function getUserCertificates(address _user) external view returns (uint256[] memory) {
        return userCertificates[_user];
    }

    function getCertificate(uint256 _certificateId) external view returns (
        uint256 courseId,
        address recipient,
        uint256 timestamp,
        uint256 score
    ) {
        Certificate memory cert = certificates[_certificateId];
        return (
            cert.courseId,
            cert.recipient,
            cert.timestamp,
            cert.score
        );
    }

    function toggleCourseStatus(uint256 _courseId) external {
        require(msg.sender == courses[_courseId].instructor || owner() == msg.sender, "Not authorized");
        courses[_courseId].isActive = !courses[_courseId].isActive;
    }
} 