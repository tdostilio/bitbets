pragma experimental ABIEncoderV2;
pragma solidity ^0.5.1;
import "./IERC20.sol";


contract BitBets {

  mapping(uint => mapping(address => uint)) userBets;
  mapping(uint => mapping(address => bool)) userWithdrawn;
  mapping(uint => address[]) takers;
  struct Bet {
    string terms;
    uint amount;
    string options;
    address oracle;
    uint outcome;
    uint totalPool;
    address paymentToken;
  }

  Bet[] public bets;

  function createBet(string memory terms, uint amount, string memory options, address paymentToken) public {
    bets.push(Bet({
      terms: terms,
      amount: amount,
      options: options,
      oracle: msg.sender,
      outcome: 0,
      totalPool: 0,
      paymentToken: paymentToken
    }));
  }

  function placeBet(uint betIndex, uint option) public payable {
    Bet memory currentBet = bets[betIndex];
    if(currentBet.paymentToken == address(0x0)) {
      require(msg.value == currentBet.amount, "Must meet the bet requirement");
    } else {
      require(IERC20(currentBet.paymentToken).allowance(msg.sender, address(this)) >= currentBet.amount, "Must have approved this bet to move tokens");
      require(IERC20(currentBet.paymentToken).transferFrom(msg.sender, address(this), currentBet.amount));
    }

    require(option > 0, "You must use 1 based indexes for choosing an option");
    if(currentBet.outcome == 0) {
      userBets[betIndex][msg.sender] = option;
      takers[betIndex].push(msg.sender);
      bets[betIndex].totalPool += currentBet.amount;
    }
  }

  function resolveBet(uint betIndex, uint outcome) public {
    Bet memory currentBet = bets[betIndex];
    require(currentBet.oracle == msg.sender, "You don't have permission to resolve this bet");
    require(outcome > 0, "Use 1 based indexes for outcome");
    bets[betIndex].outcome = outcome;
  }

  function withdraw(uint betIndex) public {
    Bet memory currentBet = bets[betIndex];
    require(currentBet.outcome > 0, "Bet is not resolved");
    require(userBets[betIndex][msg.sender] == currentBet.outcome, "You didn't select the correct answer");
    require(userWithdrawn[betIndex][msg.sender] == false, "You've already withdrawn");
    userWithdrawn[betIndex][msg.sender] = true;
    if(currentBet.paymentToken == address(0x0)) {
      address(msg.sender).transfer(currentBet.amount);
    } else {
      IERC20(currentBet.paymentToken).transfer(msg.sender, currentBet.amount);
    }
  }
}
