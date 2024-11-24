// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MithucoinStable is ERC20, Ownable {
    //Note: The code both creates a contract for stablecoin + an erc20 token
    uint256 public taxFee = 2; // 2% tax fee
    address public taxCollector;
    mapping(address => uint256) public reserves; // Collateral reserves for minting/redeeming

    event TaxFeeUpdated(uint256 newFee);
    event TaxCollectorUpdated(address newCollector);
    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralWithdrawn);

    constructor() ERC20("Mithucoin", "MITHU") Ownable(msg.sender) {
        taxCollector = msg.sender; // Set deployer as tax collector
    }

    /**
     * @dev Mint tokens by depositing collateral (e.g., USD).
     */
    function mint(uint256 usdAmount) external payable {
        require(usdAmount > 0, "Amount must be greater than zero");

        // Simulate collateral deposit (use a real system for fiat/crypto collateral handling)
        reserves[msg.sender] += usdAmount;

        // Mint tokens equivalent to the collateral
        _mint(msg.sender, usdAmount * 10**decimals());

        emit Minted(msg.sender, usdAmount * 10**decimals(), usdAmount);
    }

    /**
     * @dev Redeem tokens to withdraw collateral.
     */
    function redeem(uint256 tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");

        // Calculate collateral equivalent of tokens
        uint256 usdAmount = tokenAmount / 10**decimals();
        require(reserves[msg.sender] >= usdAmount, "Insufficient reserve backing");

        // Burn tokens and update reserve
        _burn(msg.sender, tokenAmount);
        reserves[msg.sender] -= usdAmount;

        emit Redeemed(msg.sender, tokenAmount, usdAmount);
    }

    /**
     * @dev Override transfer function to include tax mechanism.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 fee = calculateTax(amount);
        uint256 amountAfterFee = amount - fee;

        // Transfer the tax fee to the tax collector
        if (fee > 0) {
            _transfer(_msgSender(), taxCollector, fee);
        }

        // Transfer the remaining amount to the recipient
        _transfer(_msgSender(), recipient, amountAfterFee);

        return true;
    }

    /**
     * @dev Override transferFrom function to include tax mechanism.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 fee = calculateTax(amount);
        uint256 amountAfterFee = amount - fee;

        // Transfer the tax fee to the tax collector
        if (fee > 0) {
            _transfer(sender, taxCollector, fee);
        }

        // Transfer the remaining amount to the recipient
        _transfer(sender, recipient, amountAfterFee);

        // Update the allowance
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Update the tax fee percentage (only owner).
     */
    function updateTaxFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Tax fee must not exceed 10%");
        taxFee = newFee;
        emit TaxFeeUpdated(newFee);
    }

    /**
     * @dev Update the tax collector address (only owner).
     */
    function updateTaxCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Invalid tax collector address");
        taxCollector = newCollector;
        emit TaxCollectorUpdated(newCollector);
    }

    /**
     * @dev Calculate the tax fee for a given amount.
     */
    function calculateTax(uint256 amount) internal view returns (uint256) {
        return (amount * taxFee) / 100;
    }
}
