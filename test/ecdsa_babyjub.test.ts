import path = require("path");
import { expect } from 'chai';
const circom_tester = require('circom_tester').wasm;

const P = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const N = BigInt("2736030358979909402780800718157159386076813972158567259200215660948447373040");
const A = 168700n;
const D = 168696n;
const G:[bigint,bigint] = [
    5299619240641551281634865583518297030282874472190772894086521144482721001553n,
    16950150798460657717958625567821834550301663161624707787222815936182638968203n
];
function modP(x: bigint) { x = x % P; return x>=0n?x:x+P; }
function modN(x: bigint) { x = x % N; return x>=0n?x:x+N; }
function modInvP(x: bigint) { return modP(x ** (P-2n)); }
function modInvN(x: bigint) { return modN(x ** (N-2n)); }
function addPoints(p1:[bigint,bigint],p2:[bigint,bigint]):[bigint,bigint]{
    const [x1,y1]=p1; const [x2,y2]=p2;
    const beta=modP(x1*y2); const gamma=modP(y1*x2); const delta=modP(((-A*x1+y1)%P)*((x2+y2)%P));
    const tau=modP(beta*gamma); const inv1=modInvP(1n+D*tau); const inv2=modInvP(1n-D*tau);
    const x3=modP((beta+gamma)*inv1); const y3=modP((delta+A*beta-gamma)*inv2); return [x3,y3];
}
function scalarMult(p:[bigint,bigint],s:bigint):[bigint,bigint]{let r:[bigint,bigint]=[0n,1n];let b=p;let k=s;while(k>0n){if(k&1n)r=addPoints(r,b);b=addPoints(b,b);k>>=1n;}return r;}
function bigint_to_array(n:number,k:number,x:bigint){let mod=1n;for(let i=0;i<n;i++)mod*=2n;let ret:bigint[]=[];let tmp=x;for(let i=0;i<k;i++){ret.push(tmp%mod);tmp/=mod;}return ret;}
function sign(msg:bigint,priv:bigint,k:bigint){const R=scalarMult(G,k);const r=modN(R[0]);const kinv=modInvN(k);const s=modN(kinv*(msg+r*priv));return {r,s};}

describe("BabyJub ECDSA verify", function(){
    this.timeout(1000000);
    let circuit:any;
    before(async function(){
        circuit = await circom_tester(path.join(__dirname,"circuits","test_ecdsa_babyjub.circom"));
    });
    it("verify signature", async function(){
        const priv = 123456789n;
        const pub = scalarMult(G, priv);
        const msg = 555n;
        const k = 9n;
        const sig = sign(msg, priv, k);
        const rArr = bigint_to_array(64,4,sig.r);
        const sArr = bigint_to_array(64,4,sig.s);
        const msgArr = bigint_to_array(64,4,msg);
        const pubx = bigint_to_array(64,4,pub[0]);
        const puby = bigint_to_array(64,4,pub[1]);
        const witness = await circuit.calculateWitness({r:rArr,s:sArr,msghash:msgArr,pubkey:[pubx,puby]});
        expect(witness[1]).to.equal(1n);
        await circuit.checkConstraints(witness);
    });
});
