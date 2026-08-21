import Mux from "npm:@mux/mux-node";
console.log(Object.keys(new Mux({tokenId: "test", tokenSecret: "test"}).video.assets));
