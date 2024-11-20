// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Indentifier:MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Lottery Contract
 * @author Arash Kariznovi
 * @notice This is a raffle sample
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    // custom errors more gas efficient
    error Raffle__SendMoreEthToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /** Type Declarations */
    // prevent from enter raffle when it is picking up
    enum raffleState{
        OPEN,
        CALCULATING
    }
    /**  State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    raffleState private s_raffleState;

    /**
     * Events
     */
    event raffleEntered(address indexed player);
    event winnerPicked(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_raffleState = raffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough Eth!"); // not gas efficient b.c. string
        // require(msg.value >= i_entranceFee, Raffle__SendMoreEthToEnterRaffle()); // with high versions
        if(s_raffleState != raffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value <= i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }
    
        s_players.push(payable(msg.sender));
        // Events
        // 1. easier migration
        // 2. easier front end indexing
        emit raffleEntered(msg.sender);
    }

    // 1. get a random number
    // 2. use it to pick the winner
    // 3.automatically called
    function pickWinner() external {
        // if enough time has passed
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }
        s_raffleState = raffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        // Get random number from VRF
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        
    }
    // CEI: checks, effects, interactions
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Checks

        // Effects(internal contract state)
        uint256 winnerIndex  = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        s_raffleState = raffleState.OPEN;
        s_players = new address payable [](0);
        s_lastTimestamp = block.timestamp;
        emit winnerPicked(s_recentWinner);
        
        // Interactions(external contract interactions)
        (bool success,) = recentWinner.call{value:address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }

    
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
