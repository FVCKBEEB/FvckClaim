/*
______  _   _  _____  _   __  _____  _____   ___  ___  ______  ___ _____ ______ 
|  ___|| | | |/  __ \| | / / /  ___|/  __ \ / _ \ |  \/  ||  \/  ||  ___|| ___ \
| |_   | | | || /  \/| |/ /  \ `--. | /  \// /_\ \| .  . || .  . || |__  | |_/ /
|  _|  | | | || |    |    \   `--. \| |    |  _  || |\/| || |\/| ||  __| |    / 
| |    \ \_/ /| \__/\| |\  \ /\__/ /| \__/\| | | || |  | || |  | || |___ | |\ \ 
\_|     \___/  \____/\_| \_/ \____/  \____/\_| |_/\_|  |_/\_|  |_/\____/ \_| \_|

💢🤬 The FVCK Ecosystem was created for investors who hate scammers, offering innovative 
tools that allow anonymous reporting with irrefutable proof of fraud in the market. 
FVCK is a memecoin with real utility, bringing a revolution in security and transparency 
to the crypto market. 

🔗 Website: https://fvckbeeb.com
🚀 Group: https://t.me/FVCKBEEB_US
🦖 DinoBlock0x(DEV): https://t.me/DinoBlock0x 

🫂 Based Team
🔒 Safe & Transparent
🔥 Deflationary Token 
🏦 Token Meme Utility
🌟 Engaged Community 
🌍 Decentralized Autonomous Organization (DAO)

Part of our ecosystem:
🧷 Space ID. Project wallet addresses identified. 
⚖️ Snapshot. DAO management system. 
🔑 Safe.Global. Multi-signature wallet.

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============== Imports from OpenZeppelin =============== 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FVCKCLAIM
 * @notice Contract to lock BEP20/ERC20 tokens received externally (via transfer),
 *         manage a mapping of wallets authorized to claim specific balances,
 *         and allow withdrawal of these tokens only once.
 */
contract FvckClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Address of the token to be "locked" and distributed
    IERC20 public immutable token;

    // If the claim is enabled or not (global control)
    bool public claimEnabled;

    // Mapping: wallet => amount of tokens claimable
    mapping(address => uint256) claimableBalances;

    // Mapping: wallet => total tokens already claimed
    mapping(address => uint256) claimedBalances;

    // Mapping: wallet => claim blocked status
    mapping(address => bool) public claimBlocked;

    // Mapping: wallet => approval status for claim
    mapping(address => bool) public approvedForClaim;

    // For frontend and statistics
    uint256 public totalRegisteredAddresses; // Total registered addresses
    uint256 public totalAddressesClaimed; // Total addresses that claimed
    uint256 public totalAllocated; // Total sum of allocated tokens
    mapping(address => bool) private _isRegistered; // Address registration

    // Security restrictions
    uint256 private constant DECIMALS_MULTIPLIER = 10 ** 18; // Multiplier for 18 decimals
    uint256 public maxAllocationPerAddress = 500000 * DECIMALS_MULTIPLIER; // Maximum allocation per address
    uint256 public lastEmergencyWithdraw; // Last emergency withdrawal timestamp
    uint256 public emergencyWithdrawCooldown = 1 weeks; // Cooldown period for emergency withdrawals

    // Claim approval fee in WEI
    uint256 public claimApprovalFee;

    // Events for auditing
    event ClaimMade(address indexed beneficiary, uint256 amount);
    event ClaimableBatchAdded(address[] accounts, uint256[] amounts);
    event EmergencyWithdraw(address indexed owner, uint256 amount);
    event ClaimEnabled(bool enabled);
    event TokensAllocated(address indexed account, uint256 amount, uint256 totalAllocated);
    event NewAddressRegistered(address indexed account);
    event ClaimBlockedForAddress(address indexed account, bool isBlocked);
    event TokenDeposited(address indexed owner, uint256 amount);
    event ClaimApproved(address indexed account);
    event ClaimApprovalFeeUpdated(uint256 newFee);

    /**
     * @dev Constructor: sets the token to be used and configures the owner.
     *
     * @param _token Address of the ERC20/BEP20 token contract.
     */
    constructor(IERC20 _token) Ownable(msg.sender) {
        require(address(_token) != address(0), "Invalid token");
        token = _token;
        claimEnabled = false;
    }

    /**
     * @notice Allows the owner to set the claim approval fee.
     * @param _fee Fee amount in WEI.
     */
    function setClaimApprovalFee(uint256 _fee) external onlyOwner {
        claimApprovalFee = _fee;
        emit ClaimApprovalFeeUpdated(_fee);
    }

    /**
     * @notice Allows a user to pay the approval fee and enable claim eligibility.
     */
    function approveClaim() external payable {
        require(msg.value == claimApprovalFee, "Incorrect fee amount");
        approvedForClaim[msg.sender] = true;
        emit ClaimApproved(msg.sender);
    }

    /**
     * @notice Allows the owner to enable or disable the claim functionality globally.
     */
    function setClaimEnabled(bool _enabled) external onlyOwner {
        claimEnabled = _enabled;
        emit ClaimEnabled(_enabled);
    }

    /**
     * @notice Allows the owner to block or unblock the claim functionality for a specific address.
     * @param _account Address to be blocked/unblocked.
     * @param _blocked Boolean indicating whether the claim is blocked (true) or unblocked (false).
     */
    function setClaimBlockedForAddress(address _account, bool _blocked) external onlyOwner {
        claimBlocked[_account] = _blocked;
        emit ClaimBlockedForAddress(_account, _blocked);
    }

    /**
     * @notice Allows the owner to deposit tokens into the contract for distribution.
     * @param _amount Amount of tokens to deposit.
     */
    function depositTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit TokenDeposited(msg.sender, _amount);
    }

    /**
     * @notice Adds (or sums) claimable balances for multiple addresses in a single batch operation.
     *
     * @param _accounts List of addresses eligible for claims.
     * @param _amounts Corresponding token amounts (without decimals) each address can claim.
     */
    function addClaimableBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            _accounts.length == _amounts.length,
            "Array lengths do not match"
        );

        uint256 newTotalToAllocate = 0;

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i] * DECIMALS_MULTIPLIER;

            require(account.code.length == 0, "Cannot be a contract");
            require(
                claimableBalances[account] + amount <= maxAllocationPerAddress,
                "Allocation exceeds allowed limit"
            );

            if (!_isRegistered[account]) {
                _isRegistered[account] = true;
                totalRegisteredAddresses++;
                emit NewAddressRegistered(account);
            }

            claimableBalances[account] += amount;
            newTotalToAllocate += amount;

            emit TokensAllocated(account, amount, claimableBalances[account]);
        }

        require(
            contractTokenBalance() >= totalAllocated + newTotalToAllocate,
            "Insufficient contract balance for allocation"
        );

        totalAllocated += newTotalToAllocate;

        emit ClaimableBatchAdded(_accounts, _amounts);
    }

    /**
     * @notice Allows a user to claim their allocated tokens. The claim can be made only once.
     */
    function claim() external nonReentrant {
        require(claimEnabled, "Claim not enabled");
        require(!claimBlocked[msg.sender], "Claim blocked for this address");
        require(approvedForClaim[msg.sender], "Approval fee not paid");
        uint256 amount = claimableBalances[msg.sender];
        require(amount > 0, "You have no balance to claim");

        emit ClaimMade(msg.sender, amount);

        claimableBalances[msg.sender] = 0;
        totalAllocated -= amount;
        totalAddressesClaimed++;
        claimedBalances[msg.sender] += amount;

        approvedForClaim[msg.sender] = false; // Reset approval after claim

        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Allows the owner to withdraw all collected approval fees.
     */
    function withdrawApprovalFees() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No fees to withdraw");
        payable(owner()).transfer(contractBalance);
    }

    /**
     * @notice Returns the total token balance of the contract.
     */
    function contractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Allows the owner to withdraw all tokens in case of an emergency.
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "Contract has no balance");
        require(
            block.timestamp >= lastEmergencyWithdraw + emergencyWithdrawCooldown,
            "Cooldown in progress"
        );

        lastEmergencyWithdraw = block.timestamp;
        token.safeTransfer(owner(), contractBalance);

        emit EmergencyWithdraw(owner(), contractBalance);
    }

    // ==================== Frontend View Functions ====================

    /**
     * @notice Retrieves the specific claimable balance for a given address.
     * @param _account Address to query.
     */
    function getClaimableBalance(address _account) external view returns (uint256) {
        return claimableBalances[_account];
    }

    /**
     * @notice Retrieves the total tokens already claimed by a given address.
     * @param _account Address to query.
     */
    function getTotalClaimed(address _account) external view returns (uint256) {
        return claimedBalances[_account];
    }

    /**
     * @notice Checks whether a wallet can currently claim tokens.
     * @param _account Address to query.
     */
    function canClaim(address _account) external view returns (bool) {
        return (claimEnabled && !claimBlocked[_account] && approvedForClaim[_account] && claimableBalances[_account] > 0);
    }

    /**
     * @notice Retrieves statistics for the frontend interface.
     */
    function getStats()
        external
        view
        returns (
            uint256 _totalRegistered,
            uint256 _totalClaimed,
            uint256 _totalContractBalance,
            uint256 _totalAllocated,
            bool _claimEnabled
        )
    {
        _totalRegistered = totalRegisteredAddresses;
        _totalClaimed = totalAddressesClaimed;
        _totalContractBalance = contractTokenBalance();
        _totalAllocated = totalAllocated;
        _claimEnabled = claimEnabled;
    }
}
