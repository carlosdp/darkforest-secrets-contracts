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
// include "../range_proof_v2/circuit.circom";

template Main() {
    // private inputs
    signal input x1;
    signal input y1;
    signal input x2;
    signal input y2;
    signal input nonce;

    // public inputs
    signal input r;
    signal input distMax;
    signal input PLANETHASH_KEY;

    // public outputs
    signal output pub1;
    signal output pub2;
    signal output nonceHash;
    // if k difficulty, remaining k-1 bits of nonce are for effects
    signal output effect[4];

    /* check abs(x1), abs(y1), abs(x2), abs(y2) <= 2^31 */
    component n2bx1 = Num2Bits(32);
    n2bx1.in <== x1 + (1 << 31);
    component n2by1 = Num2Bits(32);
    n2by1.in <== y1 + (1 << 31);
    component n2bx2 = Num2Bits(32);
    n2bx2.in <== x2 + (1 << 31);
    component n2by2 = Num2Bits(32);
    n2by2.in <== y2 + (1 << 31);

    /* check x2^2 + y2^2 < r^2 */
    component comp2 = LessThan(64);
    signal x2Sq;
    signal y2Sq;
    signal rSq;
    x2Sq <== x2 * x2;
    y2Sq <== y2 * y2;
    rSq <== r * r;
    comp2.in[0] <== x2Sq + y2Sq;
    comp2.in[1] <== rSq;
    comp2.out === 1;

    /* check (x1-x2)^2 + (y1-y2)^2 <= distMax^2 */
    signal diffX;
    diffX <== x1 - x2;
    signal diffY;
    diffY <== y1 - y2;
    component ltDist = LessThan(64);
    signal firstDistSquare;
    signal secondDistSquare;
    firstDistSquare <== diffX * diffX;
    secondDistSquare <== diffY * diffY;
    ltDist.in[0] <== firstDistSquare + secondDistSquare;
    ltDist.in[1] <== distMax * distMax + 1;
    ltDist.out === 1;

    /* check MiMCSponge(x1,y1) = pub1, MiMCSponge(x2,y2) = pub2 */
    /*
        220 = 2 * ceil(log_5 p), as specified by mimc paper, where
        p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    */
    component mimc1 = MiMCSponge(2, 220, 1);
    component mimc2 = MiMCSponge(2, 220, 1);
    mimc1.ins[0] <== x1;
    mimc1.ins[1] <== y1;
    mimc1.k <== PLANETHASH_KEY;
    mimc2.ins[0] <== x2;
    mimc2.ins[1] <== y2;
    mimc2.k <== PLANETHASH_KEY;
    pub1 <== mimc1.outs[0];
    pub2 <== mimc2.outs[0];

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

component main {public [r, distMax, PLANETHASH_KEY]} = Main();
