# **FVCKCLAIM: Secure Token Claim System 🚀**

**FVCKCLAIM** is a robust and secure smart contract designed to manage and distribute ERC20/BEP20 tokens in a transparent and efficient manner. It allows the owner to allocate tokens to eligible addresses and provides claim functionality for users with built-in security and administrative controls.

---

## **📋 Features**

- **🔒 Security:** Includes reentrancy protection, allocation limits, and cooldowns for emergency withdrawals.
- **📊 Transparency:** Tracks statistics, including total registered addresses, claimed balances, and remaining allocations.
- **⚙️ Claim Management:** Allows the owner to control claim eligibility and manage allocations.
- **🛡️ Approval Fee:** Users must pay an approval fee to become eligible for claiming tokens.
- **🚨 Emergency Withdrawals:** Allows the owner to withdraw tokens in emergencies, with cooldown restrictions.

---

## **🏗️ How It Works**

### **For the Owner**

1. **Deposit Tokens:**
   - Use the `depositTokens(uint256 _amount)` function to deposit tokens into the contract for distribution.

2. **Allocate Tokens:**
   - Use `addClaimableBatch(address[] calldata _accounts, uint256[] calldata _amounts)` to allocate tokens to eligible addresses in batch.

3. **Set Claim Rules:**
   - Toggle claim functionality on/off with `setClaimEnabled(bool _enabled)`.
   - Block specific addresses from claiming with `setClaimBlockedForAddress(address _account, bool _blocked)`.

4. **Approve Claim Fees:**
   - Set the claim approval fee using `setClaimApprovalFee(uint256 _fee)`.

5. **Emergency Withdrawals:**
   - Withdraw all tokens with `emergencyWithdraw()`, subject to a cooldown.

---

### **For Investors**

1. **Pay Approval Fee:**
   - Use `approveClaim()` to pay the claim approval fee and become eligible to claim tokens.

2. **Claim Tokens:**
   - If allocated, claim your tokens using the `claim()` function.

3. **Check Balances:**
   - Use `getClaimableBalance(address _account)` to view your claimable balance.
   - Use `getTotalClaimed(address _account)` to check tokens you've already claimed.

---

## **🛠️ Key Functions**

### **Owner-Only Functions**
- **`depositTokens(uint256 _amount)`**: Deposits tokens for distribution.
- **`addClaimableBatch(address[] calldata _accounts, uint256[] calldata _amounts)`**: Allocates tokens to multiple addresses in batch.
- **`setClaimEnabled(bool _enabled)`**: Enables or disables global claim functionality.
- **`setClaimApprovalFee(uint256 _fee)`**: Updates the claim approval fee.
- **`setClaimBlockedForAddress(address _account, bool _blocked)`**: Blocks/unblocks claims for specific addresses.
- **`withdrawApprovalFees()`**: Withdraws all collected approval fees.
- **`emergencyWithdraw()`**: Withdraws all tokens in emergencies (subject to cooldown).

### **Investor Functions**
- **`approveClaim()`**: Pays the claim approval fee.
- **`claim()`**: Claims allocated tokens (if eligible).
- **`getClaimableBalance(address _account)`**: Views claimable tokens for an address.
- **`getTotalClaimed(address _account)`**: Checks the total claimed tokens for an address.

---

## **🔒 Security Features**

- **Reentrancy Guard:** Prevents reentrancy attacks.
- **Emergency Withdraw Cooldown:** Limits the frequency of emergency withdrawals.
- **Approval Fee System:** Ensures only eligible users can claim.
- **Allocation Limits:** Prevents over-allocation of tokens to any single address.
- **Blocked Claims:** Allows the owner to block claims for specific addresses.

---

## **📊 Stats and Transparency**

- **`getStats()`**:
  - Total registered addresses.
  - Total addresses that claimed tokens.
  - Contract's total token balance.
  - Total allocated tokens.
  - Claim status (enabled/disabled).

---

## **📈 Example Workflow**

1. **Owner** deposits 1,000,000 tokens into the contract.
2. **Owner** allocates 100 tokens each to 10 addresses using `addClaimableBatch`.
3. **Investor** pays the approval fee with `approveClaim()`.
4. **Investor** claims allocated tokens with `claim()`.
5. **Owner** monitors contract statistics using `getStats()`.

---

## **📋 FAQ**

### **1. What happens if I don’t pay the claim approval fee?**
   - You won’t be eligible to claim tokens until the fee is paid.

### **2. Can the owner block my ability to claim tokens?**
   - Yes, the owner can block specific addresses using `setClaimBlockedForAddress`.

### **3. What is the purpose of the approval fee?**
   - The approval fee is used to cover network and operational costs associated with verifying eligible investors.

### **4. Can the owner withdraw tokens at any time?**
   - The owner can perform emergency withdrawals, but only after a cooldown period.

### **5. How do I check if I can claim my tokens?**
   - Use the `canClaim(address _account)` function to verify your claim eligibility.

---

## **🌟 Conclusion**

**FVCKCLAIM** offers a transparent and secure solution for token distribution, ensuring fairness and efficiency for both owners and investors. With its robust security features and user-friendly design, this contract is a reliable tool for managing token claims.

---

For more details, visit the [FVCK Ecosystem Website](https://fvckbeeb.com) or join our [Telegram Group](https://t.me/FVCKBEEB_US).
