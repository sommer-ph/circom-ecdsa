pragma circom 2.0.2;

include "../../circuits/secp256k1.circom";

component main {public [scalar, point]} = K1_Secp256k1ScalarMult(64, 4);
