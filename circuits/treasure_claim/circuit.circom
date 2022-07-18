/*
    Prove: I know (
      x,y,perl,
      privkey,
      nullifier,
      ) such that:
    - perlin(x, y) = perl
    - PrivKeyToAddr(privkey) = pub
    - MiMCSponge(x,y,MiMCSponge(privkey),MiMCSponge(nullifier)) = nonce
    - nth bit of nonce is 1
*/

include "../../node_modules/circomlib/circuits/mimcsponge.circom"
include "../../node_modules/circomlib/circuits/poseidon.circom"
include "../../node_modules/circomlib/circuits/comparators.circom"
include "../../node_modules/circomlib/circuits/bitify.circom"
include "../range_proof/circuit.circom"
include "../perlin/perlin.circom"

template Main() {
    signal private input x;
    signal private input y;
    signal private input privkey;
    signal private input nullifier;

    signal input PLANETHASH_KEY;
    signal input SPACETYPE_KEY;
    signal input SCALE; /// must be power of 2 at most 16384 so that DENOMINATOR works
    signal input xMirror; // 1 is true, 0 is false
    signal input yMirror; // 1 is true, 0 is false
    
    signal output perl;
    signal output privkeyHash;
    signal output nullifierHash;
    signal output nonce;

    /* check abs(x), abs(y) <= 2^31 */
    component n2bx = Num2Bits(32);
    n2bx.in <== x + (1 << 31);
    component n2by = Num2Bits(32);
    n2by.in <== y + (1 << 31);

    /* check perlin(x, y) = perl */
    component perlin = MultiScalePerlin();
    perlin.p[0] <== x;
    perlin.p[1] <== y;
    perlin.KEY <== SPACETYPE_KEY;
    perlin.SCALE <== SCALE;
    perlin.xMirror <== xMirror;
    perlin.yMirror <== yMirror;
    perl <== perlin.out;

    // Check MiMCSponge(...) = nonce
    component mimc1 = MiMCSponge(2, 220, 1);
    component mimc2 = MiMCSponge(2, 220, 1);
    component mimc3 = MiMCSponge(2, 220, 1);
    
    mimc1.ins[0] <== nullifier;
    mimc1.ins[1] <== 1;
    mimc1.k <== PLANETHASH_KEY;
    nullifierHash <== mimc1.outs[0];

    mimc2.ins[0] <== privkey;
    mimc2.ins[1] <== 1;
    mimc2.k <== PLANETHASH_KEY;
    privkeyHash <== mimc2.outs[0];
    
    mimc3.ins[0] <== x;
    mimc3.ins[1] <== y;
    mimc3.k <== PLANETHASH_KEY;

    component hash = Poseidon(3);
    hash.inputs[0] <== mimc3.outs[0];
    hash.inputs[1] <== privkeyHash;
    hash.inputs[2] <== nullifier;
    nonce <== hash.out;

    // Check nonce bit
    component n2bn = Num2Bits(256);
    n2bn.in <== nonce;
    // The higher the bit we use the rarer it is to find treasure
    n2bn.out[5] === 1;
    
    // TODO: PrivKeyToAddr(privkey) = pub
}

component main = Main();