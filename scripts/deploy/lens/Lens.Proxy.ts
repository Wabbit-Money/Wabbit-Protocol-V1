import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beacon = data.contracts["LensV2.0"].beacon;
    const vaultAddress = data.contracts["VaultV2.0"].proxies[0];

    const Lens = await hre.ethers.getContractFactory("Lens");
    const lens = await hre.upgrades.deployBeaconProxy(beacon, Lens, [vaultAddress]);
    await lens.deployed();

    console.log("Deploy | Lens | Proxy | Proxy:", lens.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
