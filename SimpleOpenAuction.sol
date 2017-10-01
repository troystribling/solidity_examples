pragma solidity ^0.4.11;

contract SimpleAuction {

  address public beneficiary;

  // Time stamps are unix upoc timestamps
  uint public auctionStart;
  uint public biddingTime;

  address public highestBidder;
  uint public highestBid;

  mapping (address => uint) pendingReturns;

  bool ended;

  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  // The following is a so-called natspec comment,
  // recognizable by the three slashes.
  // It will be shown when the user is asked to
  // confirm a transaction.

  /// Create a simple auction with `_biddingTime`
  /// seconds bidding time on behalf of the
  /// beneficiary address `_beneficiary`.

  function SimpleAuction(uint _biddingTime, address _beneficiary) {
    beneficiary = _beneficiary;
    auctionStart = now;
    biddingTime = _biddingTime;
  }

  /// Bid on the auction with the value sent
  /// together with this transaction.
  /// The value will only be refunded if the
  /// auction is not won.
  function bid() payable {
    // All information regarding the bid is availble
    // in transaction. The keyword payable
    // is required for th function
    // to receive Ether

    // Be sure the auction has not completed
    require(now <= (auctionStart + biddingTime));

    // Be sure the bid is the highest
    require(msg.value > highestBid);

    if (highestBidder != 0) {
        pendingReturns[highestBidder] += highestBid;
    }
    highestBidder = msg.sender;
    highestBid = msg.value;
    HighestBidIncreased(msg.sender, msg.value);
  }

  /// Withdraw a bid that was overbid.
  function withdraw() returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
      // Set pending returns to 0 before sending return. This method
      // could be called multiple times before the followimng send returns.
      // Setting pending returns to 0 prevents amountfor be sent multiple
      // times.
      pendingReturns[msg.sender] = 0;
      if (!msg.sender.send(amount)) {
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  /// return time remaining in auction
  function timeRemaining() returns (uint) {
      uint remaining = auctionStart + biddingTime - now
      if (rmaining > 0) {
        return remaining
      } else {
        return 0
      }
  }

  /// End the auction and send the higest bid to the benificiary.
  function auctionEnd() {
    // It is a good guideline to structure functions that interact
    // with other contracts (i.e. they call functions or send Ether)
    // into three phases:
    // 1. checking conditions
    // 2. performing actions (potentially changing conditions)
    // 3. interacting with other contracts
    // If these phases are mixed up, the other contract could call
    // back into the current contract and modify the state or cause
    // effects (ether payout) to be performed multiple times.
    // If functions called internally include interaction with external
    // contracts, they also have to be considered interaction with
    // external contracts.

    // 1. Condition
    require(now >= (auctionStart + biddingTime)); // Auction bidding time has completed
    require(!ended); // This methos can only be called once

    // 2. Effects (end auction)
    ended = true;
    AuctionEnded(highestBidder, highestBid);

    // 3. interaction (transfer funds to benificiary)
    beneficiary.transfer(highestBid);
  }
}
