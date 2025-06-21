pragma circom 2.0.2;

include "./zk-identity/eth.circom";
include "./ecdsa.circom";

template K1_PrivKeyToAddr(n, k) {
    signal input privkey[k];
    signal output addr;

    component privToPub = K1_ECDSAPrivToPub(n, k);
    for (var i = 0; i < k; i++) {
        privToPub.privkey[i] <== privkey[i];
    }

    component flattenPub = K1_FlattenPubkey(n, k);
    for (var i = 0; i < k; i++) {
        flattenPub.chunkedPubkey[0][i] <== privToPub.pubkey[0][i];
        flattenPub.chunkedPubkey[1][i] <== privToPub.pubkey[1][i];
    }

    component pubToAddr = K1_PubkeyToAddress();
    for (var i = 0; i < 512; i++) {
        pubToAddr.pubkeyBits[i] <== flattenPub.pubkeyBits[i];
    }

    addr <== pubToAddr.address;
}