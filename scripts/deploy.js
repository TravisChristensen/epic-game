const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    const gameContract = await gameContractFactory.deploy(
        ["Stethoscope", "Bandage", "Ibuprofen"],
        [10, 1, 5],
        [10, 20, 30],
        ["https://i.imgur.com/u7N7fPy.jpeg", "https://i.imgur.com/NwkAoPm.jpg", "https://i.imgur.com/FavIJ2V.png"],
        "Spongebob Squarepants",
        "https://i.imgur.com/a4BzksN.jpg",
        100,
        5
    );
    await gameContract.deployed();
    console.log("Contract deployed to:", gameContract.address);

    let txn;
    txn = await gameContract.mintItem(0);
    await txn.wait();
    console.log("Minted NFT #1");

    txn = await gameContract.mintItem(1);
    await txn.wait();
    console.log("Minted NFT #2");

    txn = await gameContract.mintItem(1);
    await txn.wait();
    console.log("Minted NFT #3");

    txn = await gameContract.mintItem(2);
    await txn.wait();
    console.log("Minted NFT #4");
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();
