pragma circom 2.0.0;

include "circomlib/circuits/sha256.circom";

template Main() {
    signal input in[64];   // 64位输入
    signal output out[256]; // 256位哈希输出

    component hash = Sha256(64); // 调用Sha256函数
    for (var i = 0; i < 64; i++) {
        hash.in[i] <== in[i];
    }
    for (var i = 0; i < 256; i++) {
        out[i] <== hash.out[i];
    }
}

component main = Main();