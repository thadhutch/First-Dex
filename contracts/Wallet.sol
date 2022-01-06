//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable{

    using SafeMath for uint256; 

    struct Token {
        bytes32 ticker; 
        address tokenAddress; 
    }

    bytes32[] public tokenList; //List of the tickers

    mapping(bytes32 => Token) public tokens; 
    mapping(address => mapping(bytes32 => uint256)) public balances; //bytes will be used to track the different tokens

    modifier tokenAddressCheck(bytes32 _ticker) {
        require(tokens[_ticker].tokenAddress != address(0), 'This token isnt supported');
        _; 
    }

    function addToken(bytes32 _ticker, address _tokenAddress) onlyOwner external { //use external to save gas, because we won't need to call this function inside the contract 
        tokens[_ticker] = Token(_ticker, _tokenAddress); 
        tokenList.push(_ticker); 
    } 

    function deposit(uint256 _amount, bytes32 _ticker) tokenAddressCheck(_ticker) external {
        IERC20(tokens[_ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount); //Need a seperate approve function to happen for this to be able to go through obviously
        balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(_amount); 
    }
    
    function withdraw(uint256 _amount, bytes32 _ticker) tokenAddressCheck(_ticker) external {
        require(balances[msg.sender][_ticker] >= _amount, 'User doesnt have enough balance to withdraw this amount');
        balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(_amount); 
        IERC20(tokens[_ticker].tokenAddress).transfer(msg.sender, _amount);
    }
}
