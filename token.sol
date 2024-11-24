// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mithucoin is ERC20, Ownable {
    uint256 public taxFee = 2; // 2% tax fee
    address public taxCollector;
// Note: When compiling , set wersion to 0.8.20
    event TaxFeeUpdated(uint256 newFee);
    event TaxCollectorUpdated(address newCollector);

    constructor() ERC20("Mithucoin", "MITHU") Ownable(msg.sender) {
        // Mint the initial supply of 100 billion tokens
        _mint(msg.sender, 100_000_000_000 * 10 ** decimals());
        // Set the deployer as the initial tax collector
        taxCollector = msg.sender;
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
