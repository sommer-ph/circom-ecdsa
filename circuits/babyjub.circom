pragma circom 2.2.0;

include "bigint.circom";
include "bigint_func.circom";
include "babyjub_utils.circom";

// add two big integers, returning k+1 limbs
function BJJ_add(n, k, a, b) {
    var out[100];
    var carry = 0;
    for (var i = 0; i < k; i++) {
        var temp = a[i] + b[i] + carry;
        out[i] = temp % (1 << n);
        carry = temp / (1 << n);
    }
    out[k] = carry;
    return out;
}

function BJJ_add_mod_p(n, k, a, b, p) {
    var sum[100] = BJJ_add(n, k, a, b);
    var res[2][100] = K1_long_div(n, k, k, sum, p);
    return res[1];
}

function BJJ_sub_mod_p(n, k, a, b, p) {
    return K1_long_sub_mod_p(n, k, a, b, p);
}

function BJJ_mul_mod_p(n, k, a, b, p) {
    return K1_prod_mod_p(n, k, a, b, p);
}

function BJJ_inv_mod_p(n, k, a, p) {
    return K1_mod_inv(n, k, a, p);
}

// twisted Edwards addition
template BJJ_PointAddition(n, k) {
    signal input a[2][k];
    signal input b[2][k];
    signal output out[2][k];

    var p[100] = BJJ_get_p(n, k);
    var d[100] = BJJ_get_d(n, k);
    var aparam[100] = BJJ_get_a(n, k);
    var one[100];
    for (var i = 0; i < 100; i++) one[i] = i == 0 ? 1 : 0;

    var x1y2[100] = BJJ_mul_mod_p(n, k, a[0], b[1], p);
    var y1x2[100] = BJJ_mul_mod_p(n, k, a[1], b[0], p);
    var numx[100] = BJJ_add_mod_p(n, k, x1y2, y1x2, p);

    var x1x2[100] = BJJ_mul_mod_p(n, k, a[0], b[0], p);
    var y1y2[100] = BJJ_mul_mod_p(n, k, a[1], b[1], p);
    var prod[100] = BJJ_mul_mod_p(n, k, x1x2, y1y2, p);

    var dprod[100] = BJJ_mul_mod_p(n, k, d, prod, p);
    var denx_pre[100] = BJJ_add_mod_p(n, k, one, dprod, p);
    var denx[100];
    for (var i = 0; i < k; i++) denx[i] = denx_pre[i];
    var denx_inv[100] = BJJ_inv_mod_p(n, k, denx, p);
    var outx_pre[100] = BJJ_mul_mod_p(n, k, numx, denx_inv, p);

    var ax1x2[100] = BJJ_mul_mod_p(n, k, aparam, x1x2, p);
    var numy_pre[100] = BJJ_sub_mod_p(n, k, y1y2, ax1x2, p);
    var deny_pre_temp[100] = BJJ_sub_mod_p(n, k, one, dprod, p);
    var deny[100];
    for (var i = 0; i < k; i++) deny[i] = deny_pre_temp[i];
    var deny_inv[100] = BJJ_inv_mod_p(n, k, deny, p);
    var outy_pre[100] = BJJ_mul_mod_p(n, k, numy_pre, deny_inv, p);

    for (var i = 0; i < k; i++) {
        out[0][i] <== outx_pre[i];
        out[1][i] <== outy_pre[i];
    }
}

// doubling using addition with itself
template BJJ_PointDoubling(n, k) {
    signal input in[2][k];
    signal output out[2][k];

    component add = BJJ_PointAddition(n, k);
    for (var i = 0; i < k; i++) {
        add.a[0][i] <== in[0][i];
        add.a[1][i] <== in[1][i];
        add.b[0][i] <== in[0][i];
        add.b[1][i] <== in[1][i];
    }
    for (var i = 0; i < k; i++) {
        out[0][i] <== add.out[0][i];
        out[1][i] <== add.out[1][i];
    }
}

// simple double and add scalar multiplication
template BJJ_ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];
    signal output out[2][k];

    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== scalar[i];
    }

    signal rx[k];
    signal ry[k];
    for (var i = 0; i < k; i++) {
        rx[i] <== 0;
        if (i == 0) ry[i] <== 1; else ry[i] <== 0;
    }

    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            component dbl = BJJ_PointDoubling(n, k);
            for (var l = 0; l < k; l++) {
                dbl.in[0][l] <== rx[l];
                dbl.in[1][l] <== ry[l];
            }
            signal tx[k];
            signal ty[k];
            for (var l = 0; l < k; l++) {
                tx[l] <== dbl.out[0][l];
                ty[l] <== dbl.out[1][l];
            }
            component add = BJJ_PointAddition(n, k);
            for (var l = 0; l < k; l++) {
                add.a[0][l] <== tx[l];
                add.a[1][l] <== ty[l];
                add.b[0][l] <== point[0][l];
                add.b[1][l] <== point[1][l];
            }
            for (var l = 0; l < k; l++) {
                rx[l] <== n2b[i].out[j] * (add.out[0][l] - tx[l]) + tx[l];
                ry[l] <== n2b[i].out[j] * (add.out[1][l] - ty[l]) + ty[l];
            }
        }
    }
    for (var l = 0; l < k; l++) {
        out[0][l] <== rx[l];
        out[1][l] <== ry[l];
    }
}

// check point on curve: a x^2 + y^2 = 1 + d x^2 y^2
template BJJ_OnCurve(n, k) {
    signal input x[k];
    signal input y[k];

    var p[100] = BJJ_get_p(n, k);
    var d[100] = BJJ_get_d(n, k);
    var aparam[100] = BJJ_get_a(n, k);
    var one[100];
    for (var i = 0; i < 100; i++) one[i] = i==0?1:0;

    var x2[100] = BJJ_mul_mod_p(n, k, x, x, p);
    var y2[100] = BJJ_mul_mod_p(n, k, y, y, p);
    var left_part[100] = BJJ_add_mod_p(n, k, BJJ_mul_mod_p(n,k,aparam,x2,p), y2, p);
    var xy2[100] = BJJ_mul_mod_p(n, k, x2, y2, p);
    var right_part[100] = BJJ_add_mod_p(n, k, one, BJJ_mul_mod_p(n,k,d,xy2,p), p);
    for (var i = 0; i < k; i++) left_part[i] === right_part[i];
}
