// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaxableStableCoin {

    string public name = "TaxableStableCoin"; //editable
    string public symbol = "TSC"; //editable
    uint8 public decimals = 18; //editable
    uint256 private _totalSupply; // must be given in the deploy field
    uint256 public pegPrice; // must be given in the deploy field
    address public owner;// must be given in the deploy field
    address public taxWallet; // Address to receive tax // must be given in the deploy field
    uint256 public taxRate; // Tax rate in basis points (e.g., 100 = 1%)  // must be given in the deploy field

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TaxRateUpdated(uint256 newTaxRate);
    event TaxWalletUpdated(address newTaxWallet);

    constructor(uint256 initialSupply, uint256 initialPegPrice, address initialTaxWallet, uint256 initialTaxRate) {
        owner = msg.sender;
        pegPrice = initialPegPrice;
        taxWallet = initialTaxWallet;
        taxRate = initialTaxRate;
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Cannot transfer to the zero address");

        uint256 tax = calculateTax(amount);
        uint256 amountAfterTax = amount - tax;

        _balances[msg.sender] -= amount;
        _balances[recipient] += amountAfterTax;
        _balances[taxWallet] += tax;

        emit Transfer(msg.sender, recipient, amountAfterTax);
        emit Transfer(msg.sender, taxWallet, tax);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        require(_balances[sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Cannot transfer to the zero address");

        uint256 tax = calculateTax(amount);
        uint256 amountAfterTax = amount - tax;

        _balances[sender] -= amount;
        _balances[recipient] += amountAfterTax;
        _balances[taxWallet] += tax;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amountAfterTax);
        emit Transfer(sender, taxWallet, tax);
        return true;
    }

    function calculateTax(uint256 amount) public view returns (uint256) {
        return (amount * taxRate) / 10000; // Tax rate is in basis points (e.g., 100 = 1%)
    }

    function setTaxRate(uint256 newTaxRate) external onlyOwner {
        taxRate = newTaxRate;
        emit TaxRateUpdated(newTaxRate);
    }

    function setTaxWallet(address newTaxWallet) external onlyOwner {
        require(newTaxWallet != address(0), "Invalid tax wallet address");
        taxWallet = newTaxWallet;
        emit TaxWalletUpdated(newTaxWallet);
    }
}
