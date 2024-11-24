// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StableCoin {

    string public name = "StableCoin"; // editable
    string public symbol = "STC";  // editable
    uint8 public decimals = 18;   // editable
    uint256 private _totalSupply;  // must be given in the deploy field
    uint256 public pegPrice; // The price of 1 token in USD (with 18 decimal places)  // must be given in the deploy field
    address public owner;

    // Mapping from address to balance
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Events for minting, burning, and peg price changes
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);
    event PegPriceUpdated(uint256 newPrice);

    constructor(uint256 initialSupply, uint256 initialPegPrice) {
        owner = msg.sender; // Set the owner as the account that deploys the contract
        pegPrice = initialPegPrice; // Set the initial peg price
        _totalSupply = initialSupply * 10 ** uint256(decimals); // Adjust total supply for decimals
        _balances[owner] = _totalSupply; // Assign the initial supply to the owner
        emit Transfer(address(0), owner, _totalSupply); // Emit transfer event for the initial mint
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "StableCoin: Only the owner can call this function");
        _;
    }

    // ERC-20 Functions
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Stablecoin Functions

    // Set the peg price (used to maintain the value of the stablecoin)
    function setPegPrice(uint256 newPrice) external onlyOwner {
        pegPrice = newPrice;
        emit PegPriceUpdated(newPrice);
    }

    // Mint new stablecoins to a specified address (only owner can mint)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    // Burn stablecoins from a specified address (only owner can burn)
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit Burn(from, amount);
    }

    // Internal minting function (only callable within the contract)
    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal burning function (only callable within the contract)
    function _burn(address account, uint256 amount) internal {
        require(_balances[account] >= amount, "StableCoin: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }
}
