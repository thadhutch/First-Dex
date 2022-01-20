//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // returning an Array 

import './Account.sol'; 

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


    mapping(bytes32 => mapping(uint256 => Order[])) orderBook; 

    function getOrderBook(bytes32 _ticker, orderType _orderType) public view returns (Order[] memory) {
        return orderBook[_ticker][uint(_orderType)]; 
    }

    function createLimitOrder( orderType _orderType, bytes32 _ticker, uint256 _amount, uint256 _price) public {
        if(_orderType == orderType.Buy) {
            // require(balances[msg.sender]['ETH'] >= _amount.mul(_price));
        }
        else if(_orderType == orderType.Sell) {
            require(balances[msg.sender][_ticker] >= _amount);
        }

        Order[] storage orders = orderBook[_ticker][uint(_orderType)]; 
        orders.push(
            Order(nextOrderId, msg.sender, _orderType, _ticker, _amount, _price)
        );

        //Bubble sort 

        if(_orderType == orderType.Buy){
            for (uint i = 0; i < orders.length - 1; i++) {
                if(orders[i].price < orders[i+1].price) {
                    Order memory orderToMove = orders[i]; 
                    orders[i] = orders[i+1]; 
                    orders[i+1] = orderToMove;
                }
            }
        }
        else if(_orderType == orderType.Sell){
            for (uint i = 0; i < orders.length - 1; i++) {
                if(orders[i].price > orders[i+1].price) {
                    Order memory orderToMove = orders[i]; 
                    orders[i] = orders[i+1]; 
                    orders[i+1] = orderToMove;
                }
            }
        }

        nextOrderId++; 
    }
}