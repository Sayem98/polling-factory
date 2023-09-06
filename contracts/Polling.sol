
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
                @dev Md. Sayem Abedin


*/

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://e...content-available-to-author-only...m.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Polling.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// The polling contract for getting user vote for decisions.

contract Polling is Ownable, ReentrancyGuard{


    struct Poll{ // Polling struct.

        string name;
        string type1;
        string type1URL;
        string type2;
        string type2URL;
        string type3;
        string type3URL;
        uint[3] votes;
        uint endTime;
        string transactionProof;
        uint bnbAmount;
        mapping(address=>uint[3]) myVote;
        mapping(address=> bool) isVoted;
          
    }

                /// -> Storage Variables  ///
    address immutable public factory; // The factory address.
    uint public availablePolls;
    
    mapping(uint=> Poll) public polls;
    uint public pollNumber;
    bool public isPolling;

    IERC20 public token;

    uint public giveawayPercentage = 10;


    uint public lowerBariar = 1_000;
    uint public higherBariar = 20_000;
    


    constructor(address _token, address _factory){
        token = IERC20(_token);
        factory = _factory;
        
    }

    // events
    event pollCreated(uint indexed _id);
    event voted(address indexed _voter, uint indexed _id, uint indexed _type);


    function createPoll(
        string memory _name,
        string memory _type1,
        string memory _type1URL,
        string memory _type2,
        string memory _type2URL,
        string memory _type3,
        string memory _type3URL,
        uint _endTime,
        uint _bnbAmount
        ) public onlyOwner nonReentrant{
        
        require(availablePolls>0, "Polling limit reached");

        Poll storage _poll = polls[pollNumber];

        // Setting the poll data

        _poll.name = _name;

        _poll.type1 = _type1;
        _poll.type1URL = _type1URL;

        _poll.type2 = _type2;
        _poll.type2URL = _type2URL;

        _poll.type3 = _type3;
        _poll.type3URL = _type3URL;

        _poll.endTime = _endTime;
        _poll.transactionProof = 'N/A';
        _poll.bnbAmount = _bnbAmount;

        emit pollCreated(pollNumber);

        pollNumber++; 
        
    }

    function vote(uint _id, uint _type) public nonReentrant{
        Poll storage _poll = polls[_id];
        require(_id<pollNumber, "Not a valid pole");
        require(isPolling, "Polling is stopped");
        require(!isCompleted(_id), "The voting for this pole has ended");
        require(!_poll.isVoted[msg.sender], "You already voted");
 
        
      
        uint _ctfBalance = token.balanceOf(msg.sender);

        uint _votingPower = _ctfBalance/(lowerBariar*10**token.decimals());

        require(_votingPower>=1, "Not enough token to vote");

        if(_votingPower>20){
            _votingPower = 20;
        }

        if(_type == 1){
            _poll.votes[0] +=_votingPower;
            _poll.myVote[msg.sender][0] +=_votingPower;
        }else if(_type == 2){
            _poll.votes[1] += _votingPower;
            _poll.myVote[msg.sender][1]+=_votingPower;

        }else if(_type == 3){
            _poll.votes[2] +=_votingPower;
            _poll.myVote[msg.sender][2]+=_votingPower;

        }
        else{
            revert("Wrong type");
        }
        _poll.isVoted[msg.sender]  = true;

        emit voted(msg.sender, _id, _type);
    }


            /// Write contract functions///
    /*
     @dev set new token.
     @params _token_address is the new token address.
    
    */
    function setAvailablePolls(uint _availablePolls) public {
        // only polling factory can set this.
        require(msg.sender == factory, "Only factory can set this");
        availablePolls = _availablePolls;
    }

    function setBariar(uint _lowerBariar, uint _higherBariar) public onlyOwner{
        lowerBariar = _lowerBariar;
        higherBariar = _higherBariar;
    }

    function setTOken(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function setGiveawayPercentage(uint _percentage) public onlyOwner{
        giveawayPercentage = _percentage;
    }

    function startStopPolling(bool _state) public onlyOwner{
        require(isPolling != _state, "Already in required state");
        isPolling =_state;
    }

    

    function setTransactionProof(uint _id, string memory _transactionProof) public onlyOwner{
        Poll storage _poll = polls[_id];
        require(isCompleted(_id), "Polling has not finished yet");
        _poll.transactionProof = _transactionProof;
    }


            /// Read contract functions///

    function isCompleted(uint _id) public view returns(bool){
        Poll storage _poll = polls[_id];
        if(_poll.endTime>block.timestamp){
            return false;
        }else{
            return true;
        }
    }


    // Get poll info
    function getPoleVote(uint _id) public view returns(uint _v1, uint _v2, uint _v3){
        Poll storage _poll = polls[_id];
        _v1 = _poll.votes[0];
        _v2 = _poll.votes[1];
        _v3 = _poll.votes[2];

    }


}