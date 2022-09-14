const { ethers } = require("hardhat");

async function main() {
    const [admin] = await ethers.getSigners();
  
    console.log("Admin account:", admin.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    //  Deploy Mock Token20 contract
    console.log('Deploy Token20 Contract .........');
    const Token20 = await ethers.getContractFactory('Token20', admin);
    const name = 'DAI';
    const symbol = 'DAI';
    const decimals = 18;
    const token20 = await Token20.deploy(
        decimals, name, symbol
    );
    console.log('Tx Hash %s: ', token20.deployTransaction.hash);
    await token20.deployed();

    console.log('Token20 Contract: ', token20.address);

    console.log('\n===== DONE =====')
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
});