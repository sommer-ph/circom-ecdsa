pragma circom 2.2.0;

include "../../circuits/babyjub.circom";

component main {public [a, b]} = BJJ_PointAddition(64, 4);
