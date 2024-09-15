// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LendingBorrowing {
    struct Lender {
      uint256 amountLent;  // Amount the lender has deposited
      uint256 timestamp;   // When the lender deposited the funds
    }

    struct Borrower {
      uint256 amountBorrowed;  // Amount the borrower has borrowed
      uint256 collateral;      // Collateral deposited
      uint256 borrowTimestamp; // When the borrowing happened
    }

    mapping(address => Lender) public lenders;
    mapping(address => Borrower) public borrowers;

    uint256 public totalLendingPool;
    uint256 public interestRate = 5; // 5% simple interest for borrowers

    // Event logs
    event Lend(address indexed lender, uint256 amount);
    event Borrow(address indexed borrower, uint256 amount, uint256 collateral);
    event Repay(address indexed borrower, uint256 amount);
    event Withdraw(address indexed lender, uint256 amount);

    // Lender can deposit funds into the lending pool
    function lend() external payable {
      require(msg.value > 0, "Must lend more than 0 ETH");

      // Update lender information
      lenders[msg.sender].amountLent += msg.value;
      lenders[msg.sender].timestamp = block.timestamp;

      totalLendingPool += msg.value;


      emit Lend(msg.sender, msg.value);
    }

    // Borrower can borrow funds by depositing collateral
    function borrow(uint256 borrowAmount) external payable {
      require(borrowAmount > 0, "Borrow amount must be greater than 0");
      require(msg.value >= borrowAmount / 2, "Must provide at least 50% collateral");
      require(totalLendingPool >= borrowAmount, "Not enough funds in lending pool");

      // Update borrower information
      borrowers[msg.sender].amountBorrowed += borrowAmount;
      borrowers[msg.sender].collateral += msg.value;
      borrowers[msg.sender].borrowTimestamp = block.timestamp;

      totalLendingPool -= borrowAmount;

      // Transfer borrowed amount to the borrower
      payable(msg.sender).transfer(borrowAmount);

      emit Borrow(msg.sender, borrowAmount, msg.value);
    }

    // Borrower can repay the loan
    function repayLoan() external payable {
      require(borrowers[msg.sender].amountBorrowed > 0, "No active loan to repay");

      uint256 amountBorrowed = borrowers[msg.sender].amountBorrowed;
      uint256 interest = calculateInterest(amountBorrowed, borrowers[msg.sender].borrowTimestamp);
      uint256 totalRepayment = amountBorrowed + interest;

      require(msg.value >= totalRepayment, "Insufficient amount to repay the loan");

      // Refund collateral
      uint256 collateral = borrowers[msg.sender].collateral;
      borrowers[msg.sender].collateral = 0;
      payable(msg.sender).transfer(collateral);

      // Update lending pool and borrower's info
      totalLendingPool += msg.value - collateral;
      borrowers[msg.sender].amountBorrowed = 0;

      emit Repay(msg.sender, totalRepayment);
    }

    // Lender can withdraw funds they lent, including interest (if any)
    function withdrawLenderFunds() external {
      require(lenders[msg.sender].amountLent > 0, "No funds to withdraw");

      uint256 amountLent = lenders[msg.sender].amountLent;
      lenders[msg.sender].amountLent = 0;

      payable(msg.sender).transfer(amountLent);

      emit Withdraw(msg.sender, amountLent);
    }

    // Internal function to calculate interest based on borrowing duration and interest rate
    function calculateInterest(uint256 principal, uint256 borrowTimestamp) internal view returns (uint256) {
      uint256 borrowDuration = block.timestamp - borrowTimestamp;
      uint256 interest = (principal * interestRate * borrowDuration) / (365 days * 100);
      return interest;
    }
}
