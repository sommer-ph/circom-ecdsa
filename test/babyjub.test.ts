import path = require("path");
import { expect } from 'chai';
const circom_tester = require('circom_tester').wasm;

const P = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const A = 168700n;
const D = 168696n;

function modP(x: bigint) { x = x % P; return x >= 0n ? x : x + P; }

function addPoints(p1: [bigint,bigint], p2: [bigint,bigint]): [bigint,bigint] {
    const [x1,y1] = p1; const [x2,y2] = p2;
    const beta = modP(x1*y2);
    const gamma = modP(y1*x2);
    const delta = modP(((-A*x1 + y1) % P) * ((x2 + y2) % P));
    const tau = modP(beta*gamma);
    const inv1 = modInv(1n + D*tau);
    const inv2 = modInv(1n - D*tau);
    const x3 = modP((beta + gamma) * inv1);
    const y3 = modP((delta + A*beta - gamma) * inv2);
    return [x3,y3];
}

function modInv(x: bigint) { return modP(x ** (P-2n)); }

function scalarMult(p: [bigint,bigint], s: bigint): [bigint,bigint] {
    let res: [bigint,bigint] = [0n,1n];
    let base = p;
    let k = s;
    while (k > 0n) {
        if (k & 1n) res = addPoints(res, base);
        base = addPoints(base, base);
        k >>= 1n;
    }
    return res;
}

function bigint_to_array(n:number,k:number,x:bigint){
    let mod=1n; for(let i=0;i<n;i++) mod*=2n; let ret:bigint[]=[]; let temp=x; for(let i=0;i<k;i++){ret.push(temp%mod); temp/=mod;} return ret;
}

describe("BabyJub Point Addition", function(){
    this.timeout(1000000);
    let circuit:any;
    before(async function(){
        circuit = await circom_tester(path.join(__dirname,"circuits","test_babyjub_add.circom"));
    });
    it("add base point to itself", async function(){
        const G:[bigint,bigint] = [
            5299619240641551281634865583518297030282874472190772894086521144482721001553n,
            16950150798460657717958625567821834550301663161624707787222815936182638968203n
        ];
        const sum = addPoints(G,G);
        const ax = bigint_to_array(64,4,G[0]);
        const ay = bigint_to_array(64,4,G[1]);
        const bx = ax; const by = ay;
        const sx = bigint_to_array(64,4,sum[0]);
        const sy = bigint_to_array(64,4,sum[1]);
        const witness = await circuit.calculateWitness({a:[ax,ay], b:[bx,by]});
        expect(witness[1]).to.equal(sx[0]);
        expect(witness[2]).to.equal(sx[1]);
        expect(witness[3]).to.equal(sx[2]);
        expect(witness[4]).to.equal(sx[3]);
        expect(witness[5]).to.equal(sy[0]);
        expect(witness[6]).to.equal(sy[1]);
        expect(witness[7]).to.equal(sy[2]);
        expect(witness[8]).to.equal(sy[3]);
        await circuit.checkConstraints(witness);
    });
});

describe("BabyJub ScalarMult", function(){
    this.timeout(1000000);
    let circuit:any;
    before(async function(){
        circuit = await circom_tester(path.join(__dirname,"circuits","test_babyjub_scalarmult.circom"));
    });
    it("scalar 3", async function(){
        const G:[bigint,bigint] = [
            5299619240641551281634865583518297030282874472190772894086521144482721001553n,
            16950150798460657717958625567821834550301663161624707787222815936182638968203n
        ];
        const res = scalarMult(G,3n);
        const scalar = bigint_to_array(64,4,3n);
        const gx = bigint_to_array(64,4,G[0]);
        const gy = bigint_to_array(64,4,G[1]);
        const rx = bigint_to_array(64,4,res[0]);
        const ry = bigint_to_array(64,4,res[1]);
        const witness = await circuit.calculateWitness({scalar:scalar, point:[gx,gy]});
        expect(witness[1]).to.equal(rx[0]);
        expect(witness[2]).to.equal(rx[1]);
        expect(witness[3]).to.equal(rx[2]);
        expect(witness[4]).to.equal(rx[3]);
        expect(witness[5]).to.equal(ry[0]);
        expect(witness[6]).to.equal(ry[1]);
        expect(witness[7]).to.equal(ry[2]);
        expect(witness[8]).to.equal(ry[3]);
        await circuit.checkConstraints(witness);
    });
});
