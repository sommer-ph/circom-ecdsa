pragma circom 2.2.0;

// Baby JubJub parameters split into 64 bit limbs

function BJJ_get_p(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 4891460686036598785;
    ret[1] = 2896914383306846353;
    ret[2] = 13281191951274694749;
    ret[3] = 3486998266802970665;
    return ret;
}

function BJJ_get_order(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 7454187305358665456;
    ret[1] = 12339561404529962506;
    ret[2] = 3965992003123030795;
    ret[3] = 435874783350371333;
    return ret;
}

function BJJ_get_gx(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 2923948824128221265;
    ret[1] = 3078447844201652406;
    ret[2] = 5669102708735506369;
    ret[3] = 844278054434796443;
    return ret;
}

function BJJ_get_gy(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 5421249259631377803;
    ret[1] = 18221569726161695607;
    ret[2] = 2690670003684637165;
    ret[3] = 2700314812950295113;
    return ret;
}

function BJJ_get_a(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 168700;
    ret[1] = 0;
    ret[2] = 0;
    ret[3] = 0;
    return ret;
}

function BJJ_get_d(n, k) {
    assert(n == 64 && k == 4);
    var ret[100];
    ret[0] = 168696;
    ret[1] = 0;
    ret[2] = 0;
    ret[3] = 0;
    return ret;
}
