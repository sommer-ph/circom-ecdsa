pragma circom 2.2.0;

include "../../circuits/babyjub.circom";

component main {public [scalar, point]} = BJJ_ScalarMult(64, 4);
