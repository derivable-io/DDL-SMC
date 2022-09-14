const { ethers } = require("hardhat");

async function main() {
    const [admin] = await ethers.getSigners();
  
    console.log("Admin account:", admin.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    //  Deploy FetchPriceUniswapV2 contract
    console.log('Deploy FetchPriceUniswapV2 Contract .........');
    const Fetch = await ethers.getContractFactory('FetchPriceUniswapV2', admin);
    
    const fetch = await Fetch.deploy();
    console.log('Tx Hash %s: ', fetch.deployTransaction.hash);
    await fetch.deployed();

    console.log('FetchPriceUniswapV2 Contract: ', fetch.address);

    console.log('\n===== DONE =====')
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
});