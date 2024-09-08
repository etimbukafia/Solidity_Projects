// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// CUSTOM ERRORS
error Unauthorized();  // eeror for if the sender is not authorized (not admin)
error CandidateAlreadyRegistered(address candidateAddress);  // error for if candidate is already registered
error NoDoubleVotes(address voterAddress); // error if voter has already voted
error VoterAlreadyRegistered(address voterAddress);  // error for if voter is already registered
error VoterHasNotRegistered(address voterAddress);  // error for if voter is already registered
error UnderagedVoter(uint8 voterAge);  // error for if the registering voter is underaged


contract Voting {

    // EVENTS
    event CandidateAdded(address indexed candidateAddress); // Event for candidate registration
    event VoterAdded(address indexed voterAddress); // Event for candidate registration
    event VoteCasted(address indexed VoterAddress, address CandidateAddress); // Event to log voter has casted his vote
    event RegistrationOpened(State state);
    event RegistrationClosed(State state);
    event ElectionTime(State state);
    event ElectionEnded(State state);

    enum State { NotStarted, Registration, Deadline, Election, Ended }
    State public electionState;

    struct Voter { string voterName; uint voterAge; } // Representing the properties of a Voter

    // MAPPINGS
    mapping(address => string) public candidates; // Mapping to store candidate details by their address
    mapping(address => Voter) public voters; //Mapping to store voters
    mapping(address => bool) public hasVoted; // Mapping to track if user has voted
    mapping(address => uint32) public voteCount; // Mapping to count candidate's votes
    mapping(address => bool) public isRegistered; // Mapping to check if voter has registered

    // VARIABLES
    address private immutable i_admin; // contract deployer. Only person that can register candidates.

    constructor() { i_admin = msg.sender; electionState = State.NotStarted; }  // Constructor to set the admin

    // FUNCTIONS

    function startRegistration() public onlyAdmin inState(State.NotStarted) {
        electionState = State.Registration;
        emit RegistrationOpened(electionState);
    }

    // This function is for adding candidates.    
    function addCandidate(string memory name_, address address_) public onlyAdmin inState(State.Registration) {
        // Check if candidate is already registered
        if (bytes(candidates[address_]).length !=0) { revert CandidateAlreadyRegistered(address_); }
        candidates[address_] = name_; // Assigns candidates Name
        emit CandidateAdded(address_); // emits candidate added event
    }

    // This function is for registering voters
    // This function first checks if the voter has already registered, then checks the voter's age, before registering the voter
    function registerVoters(string memory name_, uint8 age_, address address_) public onlyAdmin inState(State.Registration) {
        if (isRegistered[address_] != false) { revert VoterAlreadyRegistered(address_); }
        if (age_ < 16) { revert UnderagedVoter(age_); }
        voters[address_] = Voter({ voterName: name_, voterAge: age_ });
        isRegistered[address_] = true;
        emit VoterAdded(address_);
    }

    function stopRegistration() public onlyAdmin inState(State.Registration) {
        electionState = State.Deadline;
        emit RegistrationOpened(electionState);
    }

    function startVoting() public onlyAdmin inState(State.Deadline) {
        electionState = State.Election;
        emit RegistrationOpened(electionState);
    }

    function castVote(address VoterAddress_, address CandidateAddress_) public onlyRegisteredVoters inState(State.Election) {
        voteCount[CandidateAddress_] += 1;
        hasVoted[VoterAddress_] = true;
        emit VoteCasted(VoterAddress_, CandidateAddress_);
    }

    function stopVoting() public onlyAdmin inState(State.Election) {
        electionState = State.Ended;
        emit RegistrationOpened(electionState);
    }

    function voteTallying(address candidateAddress_) public view onlyAdmin inState(State.Ended) returns (uint32) {
        return voteCount[candidateAddress_];
    }

    // MODIFIERS
    modifier onlyAdmin() {
        if (msg.sender != i_admin) revert Unauthorized(); // Modifier to restrict address to only the admin
        _;
    }

    modifier onlyRegisteredVoters() {
        if (isRegistered[msg.sender] == false) revert VoterHasNotRegistered(msg.sender);
        if (hasVoted[msg.sender] != false) revert NoDoubleVotes(msg.sender);
        _;
    }

    modifier inState(State _state) {
        require(electionState == _state, "Operation not allowed in current state");
        _;
    }
}