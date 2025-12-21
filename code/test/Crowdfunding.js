const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { request } = require("http");

describe("Crowdfunding", function () {

    async function deployOneFixture() {
        const target = 1000000000;
        const seconds = 10368000;
        const [manager, recepient1, recepient2, contributors1, contributors2, contributors3, contributors4] = await ethers.getSigners();

        const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
        const crowdfunding = await Crowdfunding.deploy(target, seconds);

        const deadline = await crowdfunding.deadline();
        const raisedAmount = await crowdfunding.raisedAmount();

        await crowdfunding.deployed();
        console.log(crowdfunding.address);
        return { crowdfunding, manager, recepient1, recepient2, contributors1, contributors2, contributors3, contributors4, target, deadline, raisedAmount };
    }

    describe("Deployment", function () {
        it("Should set the right deadline", async function () {
            const { crowdfunding, deadline } = await loadFixture(deployOneFixture);
            expect(await crowdfunding.deadline()).to.equal(deadline);
            console.log(deadline);
        });

        it("Should set the right manager", async function () {
            const { crowdfunding, manager } = await loadFixture(deployOneFixture);
            expect(await crowdfunding.manager()).to.equal(manager.address);
            console.log(manager.address);
        });

        it("Should fail if the deadline is not in the future", async function () {
            const latestTime = await time.latest();
            const { deadline } = await loadFixture(deployOneFixture);
            await expect(await latestTime < deadline);
        });
    });

    describe("send Ethers", function () {
        it("Should receive the funds from Contributors", async function () {
            const { crowdfunding, contributors1 } = await loadFixture(deployOneFixture);
            console.log(await crowdfunding.getBalance());
            expect(await crowdfunding.connect(contributors1).sendEth({ from: contributors1.address, value: 500 }));
            console.log(await crowdfunding.getBalance());
            console.log(await crowdfunding.totcontributors());
            console.log(await crowdfunding.contributors(contributors1.address))
        });
        it("should increase total raised amount", async function () {
            const { crowdfunding, raisedAmount } = await loadFixture(deployOneFixture);
            expect(await crowdfunding.raisedAmount() == (raisedAmount + 500));
            console.log(await raisedAmount);
        })
    });

    describe("Create Requests", function () {
        it("should create requests", async function () {
            const { crowdfunding, recepient1, manager } = await loadFixture(deployOneFixture);
            expect(await crowdfunding.connect(manager).createRequests("charity", recepient1.address, 1500, { from: manager.address }));
            console.log(await crowdfunding.request(0));
        });
    });

    describe("Vote Request", function () {
        it("should allow contributors only", async function () {

            const { crowdfunding, manager, recepient1, contributors1 } = await loadFixture(deployOneFixture);
            expect(await crowdfunding.connect(contributors1).sendEth({ from: contributors1.address, value: 500 }));
            expect(await crowdfunding.connect(manager).createRequests("charity", recepient1.address, 1500, { from: manager.address }));

            expect(await crowdfunding.connect(contributors1).voteRequest(0, { from: contributors1.address }));
            console.log(await crowdfunding.request(0));
        });

        describe("Refund", async function () {
 
            it("should give refund to the contributor only", async function () {

                const { crowdfunding, contributors1, deadline } = await loadFixture(deployOneFixture);
                expect(await crowdfunding.connect(contributors1).sendEth({ from: contributors1.address, value: 500 }));
                await time.increaseTo(deadline);

                expect(await crowdfunding.connect(contributors1).refund({ from: contributors1.address }));
                console.log(await crowdfunding.getBalance());
            });
        });
    });

    describe("Make Payments", function () {
        it("Should transfer asked value to the recepient", async function () {
            const { crowdfunding, manager, recepient1, deadline, target, contributors1, raisedAmount } = await loadFixture(deployOneFixture);

            expect(await crowdfunding.connect(contributors1).sendEth({ from: contributors1.address, value: 10000000000 }));
            expect(await crowdfunding.connect(manager).createRequests("charity", recepient1.address, 1500, { from: manager.address }));
            expect(await crowdfunding.connect(contributors1).voteRequest(0, { from: contributors1.address }));

            console.log(await crowdfunding.raisedAmount());
            await time.increaseTo(deadline);
            console.log(await target);

            expect(await crowdfunding.connect(manager).makePay(0));
            expect(await crowdfunding.request(0).completed == true);
            console.log(await crowdfunding.getBalance());
            console.log(await crowdfunding.request(0));

        });
    });
});