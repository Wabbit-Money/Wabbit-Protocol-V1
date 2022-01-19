import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.json";
import {shouldFail} from "../scripts/util/testUtils";
import {ERC20, LPool, MarginLong} from "../typechain-types";

describe("MarginLong", async function () {
    let marginLong: MarginLong;
    let token: ERC20;
    let borrowedToken: ERC20;
    let pool: LPool;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        token = await ethers.getContractAt("ERC20", config.approved[0].address);
        borrowedToken = await ethers.getContractAt("ERC20", config.approved[1].address);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("deposit and undeposit collateral into the account", async () => {
        const initialBalance = await token.balanceOf(signerAddress);

        const tokenAmount = ethers.BigNumber.from(1000000);
        await marginLong.addCollateral(token.address, tokenAmount);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance.sub(tokenAmount));
        expect(await marginLong.collateral(token.address, signerAddress)).to.equal(tokenAmount);

        expect(await marginLong.totalCollateral(token.address)).to.equal(tokenAmount);
        expect(await token.balanceOf(marginLong.address)).to.equal(tokenAmount);

        await marginLong.removeCollateral(token.address, tokenAmount);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance);
        expect(await marginLong.collateral(token.address, signerAddress)).to.equal(0);

        expect(await marginLong.totalCollateral(token.address)).to.equal(0);
        expect(await token.balanceOf(marginLong.address)).to.equal(0);
    });

    it("should not allow bad deposits", async () => {
        shouldFail(async () => await marginLong.addCollateral(lpToken.address, 0));
        shouldFail(async () => await marginLong.addCollateral(token.address, ethers.BigNumber.from(2).pow(255)));

        shouldFail(async () => await marginLong.removeCollateral(token.address, ethers.BigNumber.from(2).pow(255)));
    });

    it("should prevent bad leverage positions and should open and repay a leveraged position", async () => {
        await shouldFail(async () => await marginLong.borrow(token.address, ethers.BigNumber.from(2).pow(255)));

        const borrowTokenBalance = await borrowedToken.balanceOf(signerAddress);
        const stakeValue = await pool.stakeValue(borrowedToken.address, borrowTokenBalance);
        await pool.stake(borrowedToken.address, borrowTokenBalance);

        await shouldFail(async () => await marginLong.borrow(token.address, ethers.BigNumber.from(2).pow(255)));

        const collateralAmount = ethers.BigNumber.from(10).pow(18).mul(500);
        await marginLong.addCollateral(token.address, collateralAmount);

        await shouldFail(async () => await marginLong.borrow(token.address, ethers.BigNumber.from(2).pow(255)));

        const borrowedAmount = ethers.BigNumber.from(1000000);
        await marginLong.borrow(borrowedToken.address, borrowedAmount);

        // **** Check all of the borrow amounts and the pool liquidity etc
    });
});
