//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // returning an Array 

import './Account.sol'; 
import 'hardhat/console.sol';

contract Dex is Account {

    using SafeMath for uint256; 

    enum orderType {   
        Buy,            
        Sell
    }
    
    struct Order {
        uint256 id; 
        address trader;
        orderType _orderType; 
        bytes32 ticker; 
        uint256 amount; 
        uint256 price; 
    }

    uint256 public nextOrderId = 0; 
    address public accountContract;

    constructor (address _accountContract) {
         accountContract = _accountContract; 
    }

    mapping(bytes32 => mapping(uint256 => Order[])) orderBook; 

    function getOrderBook(bytes32 _ticker, orderType _orderType) public view returns (Order[] memory) {
        return orderBook[_ticker][uint(_orderType)]; 
    }

    function createLimitOrder( orderType _orderType, bytes32 _ticker, uint256 _amount, uint256 _price) public {

        Account account = Account(accountContract); 

        if(_orderType == orderType.Buy) {
            // require(balances[msg.sender]['ETH'] >= _amount.mul(_price));
        }
        else if(_orderType == orderType.Sell) {
            require(account.returnBalances(msg.sender, _ticker) >= _amount, 'User doesnt have enough tokens');
        }

        Order[] storage orders = orderBook[_ticker][uint(_orderType)]; 
        orders.push(
            Order(nextOrderId, msg.sender, _orderType, _ticker, _amount, _price)
        );

        //Bubble sort 
        uint i = orders.length > 0 ? orders.length - 1 : 0; //if orders.length is greater than 0 i equals orders.length - 1. If orders.length is 0, i = 0. This sets i's initial value

        if(_orderType == orderType.Buy){
            while(i > 0) {
                if(orders[i - 1].price > orders[i].price) {
                    break; 
                }
                Order memory tempOrder = orders[i - 1]; 
                orders[i - 1] = orders[i]; 
                orders[i] = tempOrder; 
                i --; 
            }
        }
        else if(_orderType == orderType.Sell){
            while (i > 0) {
                if(orders[i - 1].price < orders[i].price) {
                    break; 
                }
                Order memory tempOrder = orders[i - 1]; 
                orders[i - 1] = orders[i]; 
                orders[i] = tempOrder; 
                i --; 
            }
        }

        nextOrderId ++; 

    }
}