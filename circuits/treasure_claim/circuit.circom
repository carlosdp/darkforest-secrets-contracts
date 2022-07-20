/*
    Prove: I know (
      x, y,
      privkey,
      preimage,
      address,
      ) such that:
    - hash(x, y, privkey) = nonce
    - nth bit of nonce is 1
    - remaining bits of nonce are r2 and distmax (later)
    - PrivKeyToAddr(privkey) = pubkey
*/

include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

template Main() {
    // private inputs
    signal input x;
    signal input y;
    signal input privkey;

    // public inputs
    signal input PLANETHASH_KEY;
    signal input pubkey;
    
    // intermediate signal
    signal nonce;
    
    // public outputs
    signal output planetHash;
    signal output nonceHash;

    // Check abs(x), abs(y) <= 2^31
    component n2bx = Num2Bits(32);
    n2bx.in <== x + (1 << 31);
    component n2by = Num2Bits(32);
    n2by.in <== y + (1 << 31);

    // Check hash(...) = nonce
    component mimc1 = MiMCSponge(2, 220, 1);
    mimc1.ins[0] <== x;
    mimc1.ins[1] <== y;
    mimc1.k <== PLANETHASH_KEY;
    planetHash <== mimc1.outs[0];
    component hash = Poseidon(2);
    hash.inputs[0] <== planetHash;
    hash.inputs[1] <== privkey;
    nonce <== hash.out;
    
    component hash2 = Poseidon(1);
    hash2.inputs[0] <== nonce;
    nonceHash <== hash2.out;

    // Check nonce bit
    // The higher the bit we use the rarer it is to find treasure
    component n2bn = Num2Bits(256);
    n2bn.in <== nonce;
    n2bn.out[5] === 1;
    
    // TODO: PrivKeyToAddr(privkey) = pubkey
}

component main {public [PLANETHASH_KEY, pubkey]} = Main();
