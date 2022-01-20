// TESTS //

// the user must have Eth deposit and their eth balance should be greater than any buy order value 
// the user must have a greater token balance that the sell order they are placing 
// The buy and sell books should be numerically ordered based on price


const { expect } = require('chai'); 
const { ethers, network } = require('hardhat'); 


describe('DEX TEST', function () {


    let Account; 
    let account; 
    let Dex;
    let dex;
    let AaveToken;
    let aaveToken;  
    let owner; 
    let addr1; 
    let addr2;
    let provider; 

    before( async function () {

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners(); //Automatically give addresses 10000 ETH

        provider = ethers.getDefaultProvider(); 

        Account = await ethers.getContractFactory('Account'); 
        account = await Account.deploy(); 

        Dex = await ethers.getContractFactory('Dex'); 
        dex = await Dex.deploy(account.address); 
        
        AaveToken = await ethers.getContractFactory('AaveToken'); 
        aaveToken = await AaveToken.deploy(); 
    }); 

    it('Account should have eth balance before deposit', async function () {
        let ownerBalance = await ethers.provider.getBalance(owner.address)
        console.log(`owner has an ETH balance of ${ownerBalance}`); 
        expect(Number(ownerBalance)).to.be.greaterThan(0); 
    }); 

    it('Account needs to have a greater token balance than the sell order amount', async function () {
        let aaveBytes = await ethers.utils.formatBytes32String('Aave');

        let addTokenFunc = await account.addToken(aaveBytes, aaveToken.address); 
        await addTokenFunc.wait();  

        let approve = await aaveToken.approve(account.address, 1000)
        await approve.wait(); 
        let deposit = await account.deposit(1000, aaveBytes); 
        await deposit.wait();
        let accountBalance = await account.balances(owner.address, aaveBytes);

        let sellAmount = 100;
        let sell = await account.withdraw(sellAmount, aaveBytes); 
        await sell.wait();
        expect(Number(accountBalance)).to.be.greaterThan(sellAmount); 
    });

    it('Buy order book should be organized greatest to least', async function () {
        let aaveBytes = await ethers.utils.formatBytes32String('Aave');

        await dex.createLimitOrder(0, aaveBytes, 10, 20);
        await dex.createLimitOrder(0, aaveBytes, 10, 10);
        await dex.createLimitOrder(0, aaveBytes, 10, 30);
        await dex.createLimitOrder(0, aaveBytes, 10, 60);

        let orderBook = await dex.getOrderBook(aaveBytes, 0); // 0 is buy 1 is sell
            for (let i = 0; i < orderBook.length - 1; i++) {
                expect(Number(orderBook[i].price)).to.be.greaterThanOrEqual(Number(orderBook[i+1].price));
            }; 

    }); 

    it('Sell order book should be organized least to greatest', async function () {
        let aaveBytes = await ethers.utils.formatBytes32String('Aave');        
        await aaveToken.mint(owner.address, 500); 
        await aaveToken.approve(account.address, 500); 

        let deposit = await account.deposit(500, aaveBytes); 
        await deposit.wait();

        await dex.createLimitOrder(1, aaveBytes, 2, 25);
        await dex.createLimitOrder(1, aaveBytes, 1, 10);
        await dex.createLimitOrder(1, aaveBytes, 10, 45);

        let orderBook = await dex.getOrderBook(aaveBytes, 1); // 0 is buy 1 is sell
            for (let i = 0; i < orderBook.length - 1; i++) {
                expect(Number(orderBook[i].price)).to.be.lessThanOrEqual(Number(orderBook[i+1].price));
            }; 

    }); 
}); 