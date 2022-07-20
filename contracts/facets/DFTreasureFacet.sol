// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports
import {ABDKMath64x64} from "../vendor/libraries/ABDKMath64x64.sol";
import {LibGameUtils} from "../libraries/LibGameUtils.sol";
import {LibArtifactUtils} from "../libraries/LibArtifactUtils.sol";
import {LibPlanet} from "../libraries/LibPlanet.sol";
import {TreasureClaimVerifier} from "../TreasureClaimVerifier.sol";
import {TreasureUseVerifier} from "../TreasureUseVerifier.sol";

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
        uint256[4] memory _input
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
                  _input[0], // planetHash
                  _input[1], // nonceHash
                  _input[2], // planetHashKey
                  0 //keccak256(abi.encode(msg.sender))
              ];
          require(TreasureClaimVerifier.verifyProof(_a, _b, _c, _proofInput), "Failed treasure claim proof check");
      /* } */

      require(
          gs().planets[_input[0]].owner == msg.sender,
          "Only owner account can perform that operation on planet."
      );

      // claim treasure for msg.sender
      gs().treasures[_input[1]] = treasure;

      // todo: mark planet "treasure hunted"
    }

    function useTreasure(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[10] memory _input
    ) public notPaused {
      // verify proof of treasure use
      uint256[10] memory _proofInput =
          [
            _input[0], // _pub1,
            _input[1], // _pub2,
            _input[2], // _nonceHash,
            _input[3], // _effect0
            _input[4], // _effect1
            _input[5], // _effect2
            _input[6], // _effect3
            _input[7], // _r,
            _input[8], // _distMax,
            _input[9] // _planetHashKey
          ];
      require(TreasureUseVerifier.verifyProof(_a, _b, _c, _proofInput), "Failed treasure claim proof check");

      uint256 _nonceHash = _input[2];
      uint256 _pub1 = _input[0];
      require(isTreasureClaimed(_nonceHash), "Treasure doesn't exist");
      require(!gs().treasures[_nonceHash].used, "Treasure already used");
      require(
          gs().planets[_pub1].owner == msg.sender,
          "Only owner account can perform that operation on planet."
      );
      
      // TODO: apply treasure effects
      
      gs().treasures[_nonceHash].used = true;
    }

    function isTreasureClaimed(uint256 _nonceHash) public view returns (bool) {
      Treasure memory treasure = gs().treasures[_nonceHash];

      if (treasure.owner != address(0)) {
        return true;
      }

      return false;
    }
}
