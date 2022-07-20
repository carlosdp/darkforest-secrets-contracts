// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports
import {ABDKMath64x64} from "../vendor/libraries/ABDKMath64x64.sol";
import {LibGameUtils} from "../libraries/LibGameUtils.sol";
import {LibArtifactUtils} from "../libraries/LibArtifactUtils.sol";
import {LibPlanet} from "../libraries/LibPlanet.sol";
import {TreasureClaimVerifier} from "../TreasureClaimVerifier.sol";

// Storage imports
import {WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {
    ArrivalData,
    ArrivalType,
    Artifact,
    ArtifactType,
    DFPCreateArrivalArgs,
    DFPMoveArgs,
    Planet,
    PlanetExtendedInfo,
    PlanetExtendedInfo2,
    PlanetEventMetadata,
    PlanetEventType,
    Upgrade,
    Treasure
} from "../DFTypes.sol";

contract DFTreasureFacet is WithStorage {
    modifier notPaused() {
        require(!gs().paused, "Game is paused");
        _;
    }

    function claimTreasure(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256 _planetHash,
        uint256 _nonceHash,
        uint256 _planetHashKey
    ) public notPaused {
      // construct treasure from input
      Treasure memory treasure = Treasure({
        owner: msg.sender,
        used: false
      });

      // verify proof of treasure claim
      /* if (!snarkConstants().DISABLE_ZK_CHECKS) { */
          uint256[4] memory _proofInput =
              [
                  _planetHash,
                  _nonceHash,
                  _planetHashKey,
                  0 //keccak256(abi.encode(msg.sender))
              ];
          require(TreasureClaimVerifier.verifyProof(_a, _b, _c, _proofInput), "Failed treasure claim proof check");
      /* } */

      // claim treasure for msg.sender
      gs().treasures[_nonceHash] = treasure;

      // todo: mark planet "treasure hunted"
    }

    function isTreasureClaimed(uint256 _nonceHash) public view returns (bool) {
      Treasure memory treasure = gs().treasures[_nonceHash];

      if (treasure.owner != address(0)) {
        return true;
      }

      return false;
    }
}
