/*
    Prove: I know (
      x1,y1,x2,y2,r,distMax
      nonce,
      ) such that:
    - x2^2 + y2^2 <= r^2
    - (x1-x2)^2 + (y1-y2)^2 <= distMax^2
    - hash(nonce) = nonceHash
*/

include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

template Main() {
    // private inputs
    signal input x;
    signal input y;
    signal input nonce;

    // public inputs
    signal input r;
    signal input PLANETHASH_KEY;

    // public outputs
    signal output planetHash;
    signal output nonceHash;
    // if k difficulty, remaining k-1 bits of nonce are for effects
    signal output effect[4];

    /* check abs(x), abs(y) <= 2^31 */
    component n2bx = Num2Bits(32);
    n2bx.in <== x + (1 << 31);
    component n2by = Num2Bits(32);
    n2by.in <== y + (1 << 31);

    /* check x^2 + y^2 < r^2 */
    component comp = LessThan(64);
    signal xSq;
    signal ySq;
    signal rSq;
    xSq <== x * x;
    ySq <== y * y;
    rSq <== r * r;
    comp.in[0] <== xSq + ySq;
    comp.in[1] <== rSq;
    comp.out === 1;

    /* check MiMCSponge(x,y) = planetHash */
    component mimc = MiMCSponge(2, 220, 1);
    mimc.ins[0] <== x;
    mimc.ins[1] <== y;
    mimc.k <== PLANETHASH_KEY;
    planetHash <== mimc.outs[0];

    // Check nonce hash
    component hash = Poseidon(1);
    hash.inputs[0] <== nonce;
    nonceHash <== hash.out;
 
    // Output effects
    for (var i = 0; i<4; i++) {
        effect[i] <-- (nonce >> i) & 1;
        effect[i] * (effect[i] -1 ) === 0;
    }
}

component main {public [r, PLANETHASH_KEY]} = Main();
