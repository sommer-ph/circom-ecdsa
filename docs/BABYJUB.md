# Baby JubJub Support

This repository includes experimental circuits for the Baby JubJub twisted Edwards curve.
The prime field is `21888242871839275222246405745257275088548364400416034343698204186575808495617`.

New templates are provided in `circuits/babyjub.circom` and `circuits/ecdsa_babyjub.circom` for
basic point operations and ECDSA-style signature verification.

These circuits mirror the existing secp256k1 templates but operate over the
Baby JubJub parameters.
