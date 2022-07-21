import { ArtifactType } from "@darkforest_eth/types";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  conquerUnownedPlanet,
  createArtifactOnPlanet,
  fixtureLoader,
  increaseBlockchainTime,
  makeInitArgs,
  makeMoveArgs,
  ZERO_ADDRESS,
} from "./utils/TestUtils";
import {
  defaultWorldFixture,
  growingWorldFixture,
  World,
} from "./utils/TestWorld";
import {
  LVL0_PLANET_OUT_OF_BOUNDS,
  LVL1_ASTEROID_1,
  LVL1_ASTEROID_2,
  LVL1_ASTEROID_NEBULA,
  LVL1_PLANET_NEBULA,
  LVL1_QUASAR,
  LVL2_PLANET_SPACE,
  LVL4_UNOWNED_DEEP_SPACE,
  SMALL_INTERVAL,
  SPAWN_PLANET_1,
  SPAWN_PLANET_2,
  initializers,
  VALID_INIT_PERLIN,
} from "./utils/WorldConstants";
import { TestLocation } from "./utils/TestLocation";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { buildContractCallArgs } from "@darkforest_eth/snarks";

const { BigNumber: BN } = ethers;

describe("DarkForestTreasure", function () {
  this.timeout(1000 * 1000);
  describe("claiming treasure", function () {
    let world: World;

    async function worldFixture() {
      const world = await fixtureLoader(defaultWorldFixture);
      let initArgs = makeInitArgs(SPAWN_PLANET_1);
      // await world.user1Core.initializePlayer(...initArgs);
      // await world.user1Core.giveSpaceShips(SPAWN_PLANET_1.id);

      initArgs = makeInitArgs(SPAWN_PLANET_2);
      await world.user2Core.initializePlayer(...initArgs);
      await world.user2Core.giveSpaceShips(SPAWN_PLANET_2.id);

      await increaseBlockchainTime();
      return world;
    }

    beforeEach(async function () {
      world = await fixtureLoader(worldFixture);
    });
    
    const generateClaimProofArgs = async () => {
      const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        {
          x: 0,
          y: 0,
          privkey: ["7", "1", "0", "0"],
          PLANETHASH_KEY: 1,
        },
        "./artifacts/circom/treasure_claim.wasm",
        "./artifacts/circom/treasure_claim.zkey"
      );
      const callArgs = buildContractCallArgs(proof, publicSignals);

      return {proof, publicSignals, callArgs}
    }

    const generateUseProofArgs = async () => {
      const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        {
            x: 0,
            y: 0,
            nonce:
            "1444183896910629182013318925431233511918984337616964411210224121376998532086",
            r: 5000,
            PLANETHASH_KEY: 1,
        },
        "./artifacts/circom/treasure_use.wasm",
        "./artifacts/circom/treasure_use.zkey"
      );
      const callArgs = buildContractCallArgs(proof, publicSignals);

      return {proof, publicSignals, callArgs}
    }

    it("allows claiming a treasure from owned planet", async function () {
      const {proof, publicSignals, callArgs} = await generateClaimProofArgs();

      const planet = new TestLocation({
        hex: BigNumber.from(publicSignals[0]).toHexString().slice(2),
        perlin: VALID_INIT_PERLIN,
        distFromOrigin: 0,
      });

      // await world.contract.createPlanet({ location: planet.id, perlin: BigNumber.from(0), level: BigNumber.from(1), planetType: BigNumber.from(0), requireValidLocationId: false });
      await world.user1Core.initializePlayer(...makeInitArgs(planet));

      // note(carlos): trust me bro
      // @ts-ignore
      await world.user1Core.claimTreasure(...callArgs);
      // @ts-ignore
      // expect(await world.user2Core.claimTreasure(...callArgs)).to.be.reverted();

      await increaseBlockchainTime();

      // @ts-ignore
      expect(
        await world.user1Core.isTreasureClaimed(publicSignals[1])
      ).to.be.eq(true);
    });

    it("allows using a treasure after it is claimed", async function () {
      const {proof, publicSignals, callArgs} = await generateClaimProofArgs();

      const planet = new TestLocation({
        hex: BigNumber.from(publicSignals[0]).toHexString().slice(2),
        perlin: VALID_INIT_PERLIN,
        distFromOrigin: 0,
      });

      await world.user1Core.initializePlayer(...makeInitArgs(planet));

      // @ts-ignore
      await world.user1Core.claimTreasure(...callArgs);

      await increaseBlockchainTime();

      const { proof: useProof, publicSignals: useSignals, callArgs: useCallArgs } = await generateUseProofArgs();

      // @ts-ignore
      await world.user1Core.useTreasure(...useCallArgs);
    });
  });
});
