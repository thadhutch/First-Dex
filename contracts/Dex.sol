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
        uint filled;  
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
            require(msg.sender.balance >= _amount.mul(_price)); 
        }
        else if(_orderType == orderType.Sell) {
            require(account.returnBalances(msg.sender, _ticker) >= _amount, 'User doesnt have enough tokens');
        }

        Order[] storage orders = orderBook[_ticker][uint(_orderType)]; 
        orders.push(
            Order(nextOrderId, msg.sender, _orderType, _ticker, _amount, _price, 0)
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

    function createMarketOrder(orderType _orderType, bytes32 _ticker, uint256 _amount) public {

        Account account = Account(accountContract); 

        uint theOrderType; 
        if(_orderType == orderType.Buy) {
            theOrderType = 1;
        }
        else {
            require(account.returnBalances(msg.sender, _ticker) >= _amount, 'Insufficient token balance');
            theOrderType = 0;
        }
        
        Order[] storage orders = orderBook[_ticker][theOrderType]; 

        uint totalFilled = 0;

        for(uint i = 0; i < orders.length && totalFilled < _amount; i ++) {
            uint leftToFill = _amount.sub(totalFilled); 
            uint avaliableToFill = orders[i].amount.sub(orders[i].filled); 
            uint filled = 0; 
            if(avaliableToFill > leftToFill) {
                filled = leftToFill; 
            } 
            else {
                filled = avaliableToFill; 
            }
            totalFilled = totalFilled.add(filled); 
            orders[i].filled = orders[i].filled.add(filled); 
            uint cost = filled.mul(orders[i].price); 

            if(_orderType == orderType.Buy) {
                require(msg.sender.balance >= cost);
                address payable recipient; 
                address payable sender; 

                uint currentBuyerTokenBalance = account.returnBalances(msg.sender, _ticker);
                uint newBuyerTokenBalance = currentBuyerTokenBalance.add(filled); 
                account.editBalances(msg.sender, _ticker, newBuyerTokenBalance); 

                uint currentBuyerWETHBalance = account.returnBalances(msg.sender, _ticker);
                uint newBuyerWETHBalance = currentBuyerWETHBalance.sub(cost); 
                account.editBalances(msg.sender, _ticker, newBuyerWETHBalance); 
                

                uint currentSellerTokenBalance = account.returnBalances(orders[i].trader, _ticker);
                uint newSellerTokenBalance = currentSellerTokenBalance.sub(filled); 
                account.editBalances(orders[i].trader, _ticker, newSellerTokenBalance); 

                // would be same for WETH
                
            }
            else if(_orderType == orderType.Sell) {
                uint currentSellerBalance = account.returnBalances(msg.sender, _ticker);
                uint newSellerBalance = currentSellerBalance.sub(filled); 
                account.editBalances(msg.sender, _ticker, newSellerBalance); 

                uint currentBuyerBalance = account.returnBalances(orders[i].trader, _ticker);
                uint newBuyerBalance = currentBuyerBalance.add(filled); 
                account.editBalances(orders[i].trader, _ticker, newBuyerBalance);

                //would be same for WETH

            }
            
        }

        while(orders[i].filled == orders[i].amount && orders.length > 0) {
            for(uint i = 0; i < orders.length; i++) {
                orders[i] = orders[i + 1]; 
            }
            orders.pop(); 
        }
    }

       
    }

    receive() external payable { //allows contract to recieve ether
    }
}