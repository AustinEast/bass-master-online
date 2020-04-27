"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function requestJoinOptions(i) {
    return { requestNumber: i };
}
exports.requestJoinOptions = requestJoinOptions;
function onJoin() {
    console.log(this.sessionId, "joined.");
}
exports.onJoin = onJoin;
function onMessage(message) {
    console.log(this.sessionId, "received:", message);
}
exports.onMessage = onMessage;
function onLeave() {
    console.log(this.sessionId, "left.");
}
exports.onLeave = onLeave;
function onError(err) {
    console.log(this.sessionId, "!! ERROR !!", err.message);
}
exports.onError = onError;
function onStateChange(state) {
    console.log(this.sessionId, "new state:", state);
}
exports.onStateChange = onStateChange;
