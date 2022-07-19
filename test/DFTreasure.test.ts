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
  initializers,
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
      await world.user1Core.claimTreasure(
        ["3846203574711277120509179237998948575813693308718783633084072856135074059660", "9848328668392802605051757250739764838749703513964622766750485099881164177831"],
        [
          ["18660143780475138130744179134495907336825118449734341992668275454449204638436", "18891998562295867919824383050981508195973606328844438318482642587709044563689"],
          ["1238241857631130597747529503971951960798264444065519405589916324623590269818", "8878936299000373815880939909655528811674595462166407977760942182170592674992"],
        ],
        ["12424497389376060281092732888103146995500785786196982078671792922389692367183", "12395745038266699010282682679156668010796406604436360369516632294799899787490"],
        "18498248453363282373684781534845401002600701788145870120983744267517012766537",//SPAWN_PLANET_1.id,
        "407476154482410882571835758776556304528263090013393128863650917112091016257",
        7, //initializers.PLANETHASH_KEY,
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
