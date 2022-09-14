async function main() {
    // console.log("Verify Mock Token20 Contract ......")
    // const Token20 = '';
    // const name = '';
    // const symbol = '';
    // const decimals = 18;

    // await hre.run("verify:verify", {
    //     address: Token20,
    //     constructorArguments: [
    //         decimals, name, symbol
    //     ],
    // });

    console.log("Verify FetchPriceUniswap Contract ......")
    const FetchPriceUniswap = '0x533e331098ce304c8620270dC460EF57051C6147';

    await hre.run("verify:verify", {
        address: FetchPriceUniswap,
        constructorArguments: [],
    });

    console.log('\n===== DONE =====')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
});