pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [privkey]} = K1_ECDSAPrivToPub(64, 4);
