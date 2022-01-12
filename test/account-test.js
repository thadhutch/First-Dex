const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Account Test", function () {

  let AaveToken;
  let aaveToken;
  let Account;
  let account;
  let owner;
  let addr1; 
  let addr2; 

  before( async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
    AaveToken = await ethers.getContractFactory("AaveToken");
    aaveToken = await AaveToken.deploy();

    Account = await ethers.getContractFactory("Account");
    account = await Account.deploy();
  });

  it('Deployer should have 1000 tokens', async function () {
    let balance = await aaveToken.balanceOf(owner.address); 
    console.log(`owner has ${balance} tokens`); 
    expect(balance.toString()).to.equal('1000'); 
  });

  it('Should add token to the list', async function () {
    let aaveBytes = await ethers.utils.formatBytes32String('Aave');
    let addTokenFunc = await account.addToken(aaveBytes, aaveToken.address); 
    await addTokenFunc.wait();  
    let dexList = await account.tokenList(0); 
    expect(dexList).to.equal(aaveBytes); 
  });
  
  it('User deposit should increase their balance', async function () {
    let aaveBytes = await ethers.utils.formatBytes32String('Aave');

    let approve = await aaveToken.approve(account.address, 1000)
    await approve.wait(); 
    let deposit = await account.deposit(1000, aaveBytes); 
    await deposit.wait();
    let balanceCheck = await account.balances(owner.address, aaveBytes);
    expect(balanceCheck.toString()).to.equal('1000'); 
  });
  
  it('User withdraw should decrease their balance', async function () {
    let aaveBytes = await ethers.utils.formatBytes32String('Aave');

    let withdraw = await account.withdraw(500, aaveBytes); 
    await withdraw.wait();
    let balanceCheck = await account.balances(owner.address, aaveBytes);
    expect(balanceCheck.toString()).to.equal('500'); 
  });
  
});
