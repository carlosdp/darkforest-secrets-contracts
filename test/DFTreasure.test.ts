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
} from "./utils/WorldConstants";

const { BigNumber: BN } = ethers;

describe("DarkForestTreasure", function () {
  describe("claiming treasure", function () {
    let world: World;

    async function worldFixture() {
      const world = await fixtureLoader(defaultWorldFixture);
      let initArgs = makeInitArgs(SPAWN_PLANET_1);
      await world.user1Core.initializePlayer(...initArgs);
      await world.user1Core.giveSpaceShips(SPAWN_PLANET_1.id);

      initArgs = makeInitArgs(SPAWN_PLANET_2);
      await world.user2Core.initializePlayer(...initArgs);
      await world.user2Core.giveSpaceShips(SPAWN_PLANET_2.id);

      await increaseBlockchainTime();
      return world;
    }

    beforeEach(async function () {
      world = await fixtureLoader(worldFixture);
    });

    it("allows claiming a treasure from owned planet", async function () {
      await conquerUnownedPlanet(
        world,
        world.user1Core,
        SPAWN_PLANET_1,
        LVL1_ASTEROID_NEBULA
      );
      await increaseBlockchainTime();

      const ship = (
        await world.user1Core.getArtifactsOnPlanet(SPAWN_PLANET_1.id)
      )[0].artifact;
      const shipId = ship.id;
      // ,note(carlos): trust me bro
      // @ts-ignore
      await world.user1Core.claimTreasure(
        [
          "0x16a1e3448e72cd2978e37e4c1655d6e278b03c94370a91bfc9f9b0a681fd9327",
          "0x21501c3ab1117f7b548daacf429a1c74a9b488450c63a16c754d7b57646ce74c",
        ],
        [
          [
            "0x06591d0a1d5659c51ba0bc613526166e953fe037f1baf514db43e00a57437adc",
            "0x086e76f4ef97275a479685b21e1f50c16cb231e298dc85969203fc1d6f18f1c6",
          ],
          [
            "0x2f5ac45210c61b2ab100e7809a677160e322c8dc92089e0a1e1301fa60a3c851",
            "0x28b320614dc39ba22b44a2d015595f51f531d8187181b4815f315a9725487cd6",
          ],
        ],
        [
          "0x0277785029a4476905e4ac55e518af775a3276f05b5e06da0fec7a39c6ae4716",
          "0x2f85d209af6fdaf9c3a6be8872293c42d97d6c39b88d952fb12707602a6cba6b",
        ],
        "0x28e5a33966ceb6264312abed79feb15274222340314d3b6137009bf4b3646f49",
        "0x00e69f9295ab5ef754791b9506726aa92c5d8f3da530357b51a390bf37847c41",
        "0x0000000000000000000000000000000000000000000000000000000000000007"
      );

      await increaseBlockchainTime();
      await world.user1Core.refreshPlanet(SPAWN_PLANET_1.id);

      // @ts-ignore
      expect(await world.user1Core.isTreasureClaimed(0)).to.be.eq(true);
    });
  });
});
