pragma circom 2.2.0;

include "../../circuits/ecdsa_babyjub.circom";

component main {public [r, s, msghash, pubkey]} = BJJ_ECDSAVerifyNoPubkeyCheck(64, 4);
