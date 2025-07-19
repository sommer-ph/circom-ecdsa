pragma circom 2.2.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "babyjub_utils.circom";

// combine k limbs of n bits into a field element
template LimbsToField(n, k) {
    signal input limbs[k];
    signal output out;

    var factor = 1;
    var acc = 0;
    for (var i = 0; i < k; i++) {
        acc = acc + limbs[i] * factor;
        factor = factor * (1 << n);
    }
    out <== acc;
}

// split a field element into k limbs of n bits
template FieldToLimbs(n, k) {
    signal input in;
    signal output limbs[k];

    var bitLen = n * k <= 254 ? n * k : 254;
    component bits = Num2Bits(bitLen);
    bits.in <== in;

    component b2n[k];
    for (var i = 0; i < k; i++) {
        b2n[i] = Bits2Num(n);
        for (var j = 0; j < n; j++) {
            var idx = i * n + j;
            if (idx < bitLen) {
                bits.out[idx] ==> b2n[i].in[j];
            } else {
                b2n[i].in[j] <== 0;
            }
        }
        b2n[i].out ==> limbs[i];
    }
}

// point addition using circomlib babyjub primitives
template BJJ_PointAddition(n, k) {
    signal input a[2][k];
    signal input b[2][k];
    signal output out[2][k];

    component ax = LimbsToField(n, k);
    component ay = LimbsToField(n, k);
    component bx = LimbsToField(n, k);
    component by = LimbsToField(n, k);
    for (var i = 0; i < k; i++) {
        ax.limbs[i] <== a[0][i];
        ay.limbs[i] <== a[1][i];
        bx.limbs[i] <== b[0][i];
        by.limbs[i] <== b[1][i];
    }

    component add = BabyAdd();
    add.x1 <== ax.out;
    add.y1 <== ay.out;
    add.x2 <== bx.out;
    add.y2 <== by.out;

    component sx = FieldToLimbs(n, k);
    component sy = FieldToLimbs(n, k);
    sx.in <== add.xout;
    sy.in <== add.yout;
    for (var i = 0; i < k; i++) {
        out[0][i] <== sx.limbs[i];
        out[1][i] <== sy.limbs[i];
    }
}

// doubling uses circomlib BabyDbl
template BJJ_PointDoubling(n, k) {
    signal input in[2][k];
    signal output out[2][k];

    component ix = LimbsToField(n, k);
    component iy = LimbsToField(n, k);
    for (var i = 0; i < k; i++) {
        ix.limbs[i] <== in[0][i];
        iy.limbs[i] <== in[1][i];
    }

    component dbl = BabyDbl();
    dbl.x <== ix.out;
    dbl.y <== iy.out;

    component sx = FieldToLimbs(n, k);
    component sy = FieldToLimbs(n, k);
    sx.in <== dbl.xout;
    sy.in <== dbl.yout;
    for (var i = 0; i < k; i++) {
        out[0][i] <== sx.limbs[i];
        out[1][i] <== sy.limbs[i];
    }
}

// scalar multiplication using EscalarMulAny
template BJJ_ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];
    signal output out[2][k];

    component scField = LimbsToField(n, k);
    for (var i = 0; i < k; i++) scField.limbs[i] <== scalar[i];

    component sBits = Num2Bits(253);
    sBits.in <== scField.out;

    component px = LimbsToField(n, k);
    component py = LimbsToField(n, k);
    for (var i = 0; i < k; i++) {
        px.limbs[i] <== point[0][i];
        py.limbs[i] <== point[1][i];
    }

    component mul = EscalarMulAny(253);
    for (var i = 0; i < 253; i++) {
        mul.e[i] <== sBits.out[i];
    }
    mul.p[0] <== px.out;
    mul.p[1] <== py.out;

    component sx = FieldToLimbs(n, k);
    component sy = FieldToLimbs(n, k);
    sx.in <== mul.out[0];
    sy.in <== mul.out[1];
    for (var i = 0; i < k; i++) {
        out[0][i] <== sx.limbs[i];
        out[1][i] <== sy.limbs[i];
    }
}

// check point lies on curve using BabyCheck
template BJJ_OnCurve(n, k) {
    signal input x[k];
    signal input y[k];

    component fx = LimbsToField(n, k);
    component fy = LimbsToField(n, k);
    for (var i = 0; i < k; i++) {
        fx.limbs[i] <== x[i];
        fy.limbs[i] <== y[i];
    }

    component chk = BabyCheck();
    chk.x <== fx.out;
    chk.y <== fy.out;
}
