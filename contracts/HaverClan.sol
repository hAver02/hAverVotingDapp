// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract HaverVoting is Ownable, AutomationCompatible{
    using Counters for Counters.Counter;
    Counters.Counter private _clanId;
    Counters.Counter private _voteId;

    uint private CreateClanPrice = 0.0001 ether;
    uint private constant MONTH_IN_SECONDS = 15 minutes;
    uint private constant VOTE_DURATION = 5 minutes; // Duración de la votación en segundos
    uint private constant VOTE_END_GRACE_PERIOD = 5 minutes; // Período de gracia para el fin de la votación

    struct VoteForLeader {
        uint voteId;
        mapping(address => bool) hasVoted;
        mapping(address => uint) votes;
        mapping(address => address) whoVote;
        address winningCandidate;
        bool isActive;
        uint endTime; // Fin de la votacion!
    }

    struct Clan {
        string name;
        uint clanId;
        address[] members;
        address leader;
        mapping(uint => VoteForLeader) votes;
        uint[] idsVotes;
        uint currentVoteId;
        uint lastVoteTime; // Marca de tiempo para la última votación
        uint lastVoteEndTime; // Marca de tiempo para el final de la última votación
    }

    constructor()Ownable(){}

    mapping(uint => Clan) public clans;
    mapping(address => uint) public userClan;
    uint[] public clanIds;
    VoteForLeader[] public votes;

    modifier onlyLeaderOfClan(uint clanId) {
        require(clans[clanId].leader == msg.sender, "You are not the leader of this clan!");
        _;
    }

    modifier onlyMemberOfClan(uint clanId) {
        require(isMember(clanId, msg.sender), "You are not a member of this clan");
        _;
    }

    modifier clanExists(uint clanId) {
        require(clanId < _clanId.current(), "Clan does not exist");
        _;
    }


    // FUNCIONES

    function verifyID0(address _address) internal view returns(bool){
        for (uint i = 0 ; i < clans[0].members.length ; i++) {
            if(clans[0].members[i] == _address) {
                return false;
            }
        }

        return true;
    }

    function createClan(string memory _name) public payable {
        require(msg.value == CreateClanPrice, "Incorrect amount sent");
        require(userClan[msg.sender] == 0 && ( _clanId.current() == 0 || verifyID0(msg.sender) ), "You are in other clan" );
        
        uint clanId = _clanId.current();
        Clan storage newClan = clans[clanId];
        newClan.clanId = clanId;
        newClan.name = _name;
        newClan.members.push(msg.sender);
        newClan.leader = msg.sender;
        newClan.lastVoteTime = block.timestamp;

        userClan[msg.sender] = clanId;
        clanIds.push(clanId);
        _clanId.increment();

        if (msg.value > CreateClanPrice) {
            payable(msg.sender).transfer(msg.value - CreateClanPrice);
        }
    }

    function addMember(uint clanId, address member) public onlyLeaderOfClan(clanId) clanExists(clanId) {
        require(member != address(0), "Invalid member address");
        require(userClan[member] == 0, "User is already in a clan");

        clans[clanId].members.push(member);
        userClan[member] = clanId;
    }

    function isMember(uint clanId, address user) public view clanExists(clanId) returns (bool) {
        Clan storage clan = clans[clanId];
        for (uint i = 0; i < clan.members.length; i++) {
            if (clan.members[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getClanMembers(uint clanId) public view clanExists(clanId) returns (address[] memory) {
        return clans[clanId].members;
    }

    function getAllClans() public view returns (
        uint[] memory ids,
        string[] memory names,
        address[] memory leaders,
        address[][] memory members,
        uint[] memory lastVoteTimes,
        uint[] memory lastVoteEndTimes
    ) {
        uint length = clanIds.length;
        ids = new uint[](length);
        names = new string[](length);
        leaders = new address[](length);
        members = new address[][](length);
        lastVoteTimes = new uint[](length);
        lastVoteEndTimes = new uint[](length);

        for (uint i = 0; i < length; i++) {
            uint id = clanIds[i];
            Clan storage clan = clans[id];
            ids[i] = clan.clanId;
            names[i] = clan.name;
            leaders[i] = clan.leader;
            members[i] = clan.members;
            lastVoteTimes[i] = clan.lastVoteTime;
            lastVoteEndTimes[i] = clan.lastVoteEndTime;
        }
    }

    function getClanDetails(uint clanId) public view clanExists(clanId) returns (
        string memory name,
        address[] memory members,
        address leader,
        uint[] memory idsVotes,
        uint currentVoteId,
        uint lastVoteTime,
        uint lastVoteEndTime
    ){
        Clan storage clan = clans[clanId];
        return (
            clan.name,
            clan.members,
            clan.leader,
            clan.idsVotes,
            clan.currentVoteId,
            clan.lastVoteTime,
            clan.lastVoteEndTime
            );
    }

    function getVoteDetails(uint clanId, uint voteId) public view returns (
        address winningCandidate,
        bool isActive,
        uint endTime
    ) {
        VoteForLeader storage vote = clans[clanId].votes[voteId];
        return (
            vote.winningCandidate,
            vote.isActive,
            vote.endTime
        );
    }
        
    function createNewVote(uint clanId) public clanExists(clanId) {
        Clan storage clan = clans[clanId];

        // Verifica si la última votación fue hace más de un mes
        require(block.timestamp >= clan.lastVoteTime + MONTH_IN_SECONDS, "A vote can only be created once a month");

        // Verifica si ya hay una votación activa
        require(clan.currentVoteId == 0 || !clan.votes[clan.currentVoteId].isActive, "A vote is already active");

        uint voteId = _voteId.current();
        VoteForLeader storage newVote = clan.votes[voteId];
        newVote.voteId = voteId;
        newVote.isActive = true;
        newVote.endTime = block.timestamp + VOTE_DURATION; // Establece el tiempo de finalización de la votación

        // Establece el ID de la votación actual
        clan.currentVoteId = voteId;
        clan.lastVoteTime = block.timestamp;
        clan.lastVoteEndTime = newVote.endTime; // Actualiza el tiempo de finalización de la última votación
        clan.idsVotes.push(voteId);
        _voteId.increment();

    }

    function voteForLeader(uint clanId, address candidate) public onlyMemberOfClan(clanId) clanExists(clanId) {
        Clan storage clan = clans[clanId];
        uint voteId = clan.currentVoteId;
        // Verifica que la votación esté activa y que no haya terminado
        require(clan.votes[voteId].isActive, "No active vote in progress");
        require(block.timestamp < clan.votes[voteId].endTime, "The vote has ended");

        // Verifica que el candidato sea un miembro del clan
        require(isMember(clanId, candidate), "Candidate is not a clan member");
        // Verifica que el usuario no haya votado ya
        require(!clan.votes[voteId].hasVoted[msg.sender], "You have already voted");

        // Registra el voto
        VoteForLeader storage vote = clan.votes[voteId];
        vote.whoVote[msg.sender] = candidate; 

        vote.votes[candidate]++;
        vote.hasVoted[msg.sender] = true;
        
    }

    function endVote(uint clanId) public  clanExists(clanId) {
        Clan storage clan = clans[clanId];
        uint voteId = clan.currentVoteId;
        VoteForLeader storage vote = clan.votes[voteId];

        // Verifica que la votación esté activa y que haya terminado
        require(vote.isActive, "No active vote in progress");
        require(block.timestamp >= vote.endTime, "The vote is still ongoing");

        // Determina al ganador
        address leadingCandidate;
        uint highestVotes;
        for (uint i = 0; i < clan.members.length; i++) {
            address member = clan.members[i];
            if (vote.votes[member] > highestVotes) {
                highestVotes = vote.votes[member];
                leadingCandidate = member;
            }
        }
        if(leadingCandidate != address(0)){
            clan.leader = leadingCandidate;
            vote.winningCandidate = leadingCandidate;
        }
        // clan.currentVoteId = 0;
        vote.isActive = false; // Finaliza la votación
    }

    function checkUpkeep(bytes calldata /* performData */) external view override
        returns (bool upkeepNeeded, bytes memory /* performData */) {
            bool createVoteNeeded = false;
            bool endVoteNeeded = false;
        
            uint length = clanIds.length;
            for (uint i = 0; i < length; i++) {
                uint clanId = clanIds[i];
                Clan storage clan = clans[clanId];
                uint voteId = clan.currentVoteId;

            
                    // Verifica si se necesita cerrar una votación pasada
                if (clan.votes[voteId].isActive && block.timestamp >= clan.votes[voteId].endTime + VOTE_END_GRACE_PERIOD) {
                    endVoteNeeded = true;
                }
    

                // Verifica si es momento de crear una nueva votación
                if (block.timestamp >= clan.lastVoteTime + MONTH_IN_SECONDS && (clan.currentVoteId == 0 || !clan.votes[clan.currentVoteId].isActive)) {
                    createVoteNeeded = true;
                }
        }

        upkeepNeeded = createVoteNeeded || endVoteNeeded;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        uint length = clanIds.length;
        for (uint i = 0; i < length; i++) {
            uint clanId = clanIds[i];
            Clan storage clan = clans[clanId];
            uint voteId = clan.currentVoteId;

            if (voteId != 0 && clan.votes[voteId].isActive && block.timestamp >= clan.votes[voteId].endTime + VOTE_END_GRACE_PERIOD) {
                endVote(clanId); // Finaliza la votación pasada
            }

            // Crea una nueva votación si es necesario
            if (block.timestamp >= clan.lastVoteTime + MONTH_IN_SECONDS && (clan.currentVoteId == 0 || !clan.votes[clan.currentVoteId].isActive)) {
                createNewVote(clanId); // Crea una nueva votación
            }
        }
    }


}
