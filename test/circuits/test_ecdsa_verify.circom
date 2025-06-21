pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [r, s, msghash, pubkey]} = K1_ECDSAVerifyNoPubkeyCheck(64, 4);
