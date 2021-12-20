//SPDX-License-Identifier:MIT
pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import {randomness_interface} from "./interfaces/randomness_interface.sol";
import {governance_interface} from "./interfaces/governance_interface.sol";
contract Lottery is ChainlinkClient{
	enum Lottery_Status{OPEN, CLOSED, LOADING}
	Lottery_Status public lottery_status;
	address payable[] public participant;
	uint256 public lotterry_ID;
	governance_interface public governance;
	uint256 public MINIMUM = 10000000000000000;
	uint256 public ORACLE_PAYMENT = 100000000000000000;
	address CHAINLINK_ALARM_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    bytes32 CHAINLINK_ALARM_JOB_ID = "2ebb1c1a4b1e4229adac24ee0b5f784f";
    uint256 public duration = 3600;

	constructor() public{
		setPublicChainlinkToken();
		lotterry_ID=1;
		lottery_status=Lottery_Status.CLOSED;
	}


	function start_Lottery () public{
		require(lottery_status == Lottery_Status.CLOSED,"Can't Enter The Lottery Now");
		lottery_status = Lottery_Status.OPEN;
		Chainlink.Request memory req = buildChainlinkRequest(CHAINLINK_ALARM_JOB_ID, address(this), this.fulfill_alarm.selector);
		req.addUint("until", now + duration);
		sendChainlinkRequestTo(CHAINLINK_ALARM_ORACLE, req, ORACLE_PAYMENT);
	}
	function fulfill_alarm (bytes32 _requestID) public recordChainlinkFulfillment(_requestID){
		require(lottery_status == Lottery_Status.OPEN,"Entry period hasn't started");
		lottery_status = Lottery_Status.LOADING;
		lotterry_ID= lotterry_ID + 1;
		pickWinner();
	}

	function enter() public payable{

		assert (msg.value == MINIMUM);
		assert (lottery_status == Lottery_Status.OPEN);
		participant.push(msg.sender);
	}

	function pickWinner() private{
		require(lottery_status == Lottery_Status.LOADING, "It's not time to select the Winner");
		randomness_interface(governance.randomness()).getRandom(lotterry_ID, lotterry_ID);
	}

	function fulfill_random(uint256 randomness) external{
		require(lottery_status == Lottery_Status.LOADING, "It's not time to select the Winner");
		require(randomness>0 , "random not found");
		uint256 index = randomness % participant.length;
		participant[index].transfer(address(this).balance);
		participant = new address payable[] (0);
		lottery_status = Lottery_Status.CLOSED;
	}
}