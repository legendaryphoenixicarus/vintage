// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./TWAPOracleUpdater.sol";
import "hardhat/console.sol";
import "./IBEP20.sol";


contract VintageToken is TWAPOracleUpdater {
    using SafeMath for uint256;

    uint256 vitprice = 50;
    uint256 bep20Multiplier = 10**18;

    address[] public nonCirculatingAddresses;
    bool public _tradeEnabled = false;
    address public busdaddress;
    address public liquidityAddress = address(0xD22dc631A3908E057d422Ad7846536B12F8af162);

    event TradeEnabled(uint256 timestamp, bool enabled);

    constructor(address busd) TWAPOracleUpdater("Vintage Token", "VIT", 9) {
        busdaddress = busd;
    }

    function mint(address account_, uint256 amount_) external onlyMinter() {
        _mint(account_, amount_);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        console.log("here is I want");
        console.log(owner());

        if(sender != owner() && recipient != owner())
        {
            console.log("really want");
            require(_tradeEnabled, "Trade is not yet open.");
        }
        
        this.tax(sender, recipient, amount, busdaddress);
        _transfer(sender, recipient, amount);
        
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }    

    function presale(uint256 amount, address busdAddressClone) public {
                
        uint256 balance = this.balanceOf(msg.sender);
        console.log("amount", amount);
        require((30*(10 ** 9)-balance) > amount * (10**9), "Your VIT exceed 30");
        
        _mint(msg.sender, amount*(10**9));
        
        console.log("balance", IBEP20(busdAddressClone).balanceOf(msg.sender));
        
        require(IBEP20(busdAddressClone).balanceOf(msg.sender) > amount*vitprice*bep20Multiplier, "Your BUSD exceed allowance");
        IBEP20(busdAddressClone).transferFrom(msg.sender, liquidityAddress, amount*vitprice*bep20Multiplier);
    }

    function tax(address sender, address recipient, uint256 amount, address busdAddressClone) public {
                
        uint256 balance = this.balanceOf(sender);
        console.log("tax");
        console.log("balance", balance);
        console.log("balance", amount);
        require(balance > amount * (10**9), "Your amount exceeds your balance");
       
        this.transferFrom(sender, recipient, amount * (10**9));

        require(IBEP20(busdAddressClone).balanceOf(recipient) > amount*vitprice*bep20Multiplier, "Your BUSD exceed allowance");
        
        IBEP20(busdAddressClone).transferFrom(recipient, sender, amount*vitprice*bep20Multiplier*97/100);
        IBEP20(busdAddressClone).transferFrom(recipient, liquidityAddress, amount*vitprice*bep20Multiplier*3/100);
        // IBEP20(busdAddressClone).transferFrom(msg.sender, liquidityAddress, amount*vitprice*bep20Multiplier/100*3);
        
    }

    function tradeEnabled() public onlyOwner 
    {
        _tradeEnabled = true;
        emit TradeEnabled(block.timestamp, true);
    }  

}
 