pragma circom 2.2.0;

include "bigint.circom";
include "bigint_func.circom";
include "babyjub.circom";
include "babyjub_utils.circom";

// r, s, msghash and pubkey are each represented with k 64-bit limbs
// ECDSA verification without pubkey curve check
template BJJ_ECDSAVerifyNoPubkeyCheck(n, k) {
    signal input r[k];
    signal input s[k];
    signal input msghash[k];
    signal input pubkey[2][k];
    signal output result;

    var order[100] = BJJ_get_order(n, k);
    var p[100] = BJJ_get_p(n, k);
    var gx[100] = BJJ_get_gx(n, k);
    var gy[100] = BJJ_get_gy(n, k);

    var sinv[100] = BJJ_inv_mod_p(n, k, s, order);

    var u1_pre[100] = BJJ_mul_mod_p(n, k, msghash, sinv, order);
    var u2_pre[100] = BJJ_mul_mod_p(n, k, r, sinv, order);

    component g_mult = BJJ_ScalarMult(n, k);
    for (var i = 0; i < k; i++) {
        g_mult.scalar[i] <== u1_pre[i];
        g_mult.point[0][i] <== gx[i];
        g_mult.point[1][i] <== gy[i];
    }

    component pub_mult = BJJ_ScalarMult(n, k);
    for (var i = 0; i < k; i++) {
        pub_mult.scalar[i] <== u2_pre[i];
        pub_mult.point[0][i] <== pubkey[0][i];
        pub_mult.point[1][i] <== pubkey[1][i];
    }

    component sum = BJJ_PointAddition(n, k);
    for (var i = 0; i < k; i++) {
        sum.a[0][i] <== g_mult.out[0][i];
        sum.a[1][i] <== g_mult.out[1][i];
        sum.b[0][i] <== pub_mult.out[0][i];
        sum.b[1][i] <== pub_mult.out[1][i];
    }

    component cmp[k];
    signal eqcnt[k-1];
    for (var i = 0; i < k; i++) {
        cmp[i] = IsEqual();
        cmp[i].in[0] <== sum.out[0][i];
        cmp[i].in[1] <== r[i];
        if (i > 0) {
            if (i == 1) eqcnt[i-1] <== cmp[0].out + cmp[1].out;
            else eqcnt[i-1] <== eqcnt[i-2] + cmp[i].out;
        }
    }
    component res_cmp = IsEqual();
    res_cmp.in[0] <== k;
    res_cmp.in[1] <== eqcnt[k-2];
    result <== res_cmp.out;
}

template BJJ_ECDSAVerify(n, k) {
    signal input r[k];
    signal input s[k];
    signal input msghash[k];
    signal input pubkey[2][k];
    signal output result;

    component ver = BJJ_ECDSAVerifyNoPubkeyCheck(n, k);
    for (var i = 0; i < k; i++) {
        ver.r[i] <== r[i];
        ver.s[i] <== s[i];
        ver.msghash[i] <== msghash[i];
        ver.pubkey[0][i] <== pubkey[0][i];
        ver.pubkey[1][i] <== pubkey[1][i];
    }
    result <== ver.result;

    component check = BJJ_OnCurve(n, k);
    for (var i = 0; i < k; i++) {
        check.x[i] <== pubkey[0][i];
        check.y[i] <== pubkey[1][i];
    }
}
