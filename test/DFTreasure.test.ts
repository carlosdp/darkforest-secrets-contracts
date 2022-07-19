import { ArtifactType } from '@darkforest_eth/types';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import {
  conquerUnownedPlanet,
  createArtifactOnPlanet,
  fixtureLoader,
  increaseBlockchainTime,
  makeInitArgs,
  makeMoveArgs,
  ZERO_ADDRESS,
} from './utils/TestUtils';
import { defaultWorldFixture, growingWorldFixture, World } from './utils/TestWorld';
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
} from './utils/WorldConstants';

const { BigNumber: BN } = ethers;

describe('DarkForestTreasure', function () {
  describe('claiming treasure', function () {
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

    it('allows claiming a treasure from owned planet', async function () {
      await conquerUnownedPlanet(world, world.user1Core, SPAWN_PLANET_1, LVL1_ASTEROID_NEBULA);
      await increaseBlockchainTime();

      const ship = (await world.user1Core.getArtifactsOnPlanet(SPAWN_PLANET_1.id))[0].artifact;
      const shipId = ship.id;
      // note(carlos): trust me bro
      // @ts-ignore
      await world.user1Core.claimTrasure(
        [0, 0],
        [
          [0, 0],
          [0, 0],
        ],
        [0, 0],
        SPAWN_PLANET_1,
        0
      );

      await increaseBlockchainTime();
      await world.user1Core.refreshPlanet(SPAWN_PLANET_1.id);

      // @ts-ignore
      expect(await world.user1Core.isTreasureClaimed(0)).to.be.eq(
        true
      );
    });
  });
});
