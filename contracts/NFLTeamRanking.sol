pragma solidity >=0.6.0 <0.9.0;

contract NFLRank {

    uint256 public NE;
    uint256 public SF;
    uint256 public PIT;
    uint256 public DAL;
    uint256 public GB;
    uint256 public LV;

    struct Vote {
        address voter;
        uint256 enumVlaue;
    } //stores address of voter, and vote

    enum NFLTeams { NE, SF, PIT, DAL, GB, LV }

    Vote[] public votes;

    event voteMade (address voter, NFLTeams team);


    function seeAllVotes() external view returns(Vote[] memory) {
        return votes;
    }

    function voteOnTeam(uint256 enumValue) external {
        address voter = msg.sender;
        votes.push(Vote(voter, enumValue));
        voteCounter(enumValue);
        emit voteMade(voter, NFLTeams(enumValue));
    }

    function voteCounter(uint256 _enumVote) internal {
        if (_enumVote == 0) {
            NE = NE + 1;
        }
        else if (_enumVote == 1) {
            SF = SF + 1;
        }
        else if (_enumVote == 2) {
            PIT = PIT + 1;
        }
        else if (_enumVote == 3) {
            DAL = DAL + 1;
        }
        else if (_enumVote == 4) {
            GB = GB + 1;
        }
        else {
            LV = LV + 1;
        }
    }
}
