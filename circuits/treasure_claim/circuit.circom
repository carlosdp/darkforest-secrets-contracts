/*
    Prove: I know (
      x, y, privkey,
      ) such that:
    - hash(x, y, privkey) = nonce
    - nth bit of nonce is 1 where n is treasure rarity
    - PrivKeyToAddr(privkey) = pubkey
*/

include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../circom-ecdsa/eth_addr.circom";

template Main(TREASURE_RARITY, PRIVKEY_LEN) {
    // private inputs
    signal input x;
    signal input y;
    signal input privkey[PRIVKEY_LEN];

    // public inputs
    signal input PLANETHASH_KEY;
    
    // intermediate signal
    signal nonce;
    
    // public outputs
    signal output planetHash;
    signal output nonceHash;
    signal output pubkey;

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
    component hash = Poseidon(1 + PRIVKEY_LEN);
    hash.inputs[0] <== planetHash;
    for (var i = 0; i < PRIVKEY_LEN; i++) {
      hash.inputs[i + 1] <== privkey[i];
    }
    nonce <== hash.out;
    
    component hash2 = Poseidon(1);
    hash2.inputs[0] <== nonce;
    nonceHash <== hash2.out;

    // Check nonce bit
    // The higher the bit we use the rarer it is to find treasure
    component n2bn = Num2Bits(256);
    n2bn.in <== nonce;
    n2bn.out[TREASURE_RARITY] === 1;
    
    // Check PrivKeyToAddr(privkey) = pubkey
    component eth_addr = PrivKeyToAddr(64, 4);
    for (var i = 0; i < PRIVKEY_LEN; i++) {
      eth_addr.privkey[i] <== privkey[i];
    }
    pubkey <== eth_addr.addr;
}

component main {public [PLANETHASH_KEY]} = Main(5, 4);
