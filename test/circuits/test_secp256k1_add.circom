pragma circom 2.0.2;

include "../../circuits/secp256k1.circom";

component main {public [a, b]} = K1_Secp256k1AddUnequal(64, 4);
