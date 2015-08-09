import {Socket} from "phoenix"

let timestamp = function() {
  let time = new Date();
  return [time.getHours(), time.getMinutes(), time.getSeconds()]
           .map(n => ("0" + n).slice(-2)).join(':');
}

let chatInput = $("#chat-input");
let messagesContainer = $("#messages");

let socket = new Socket("/socket");
socket.connect({username: "User" + Math.ceil(Math.random() * 10000)});
let chan = socket.chan("rooms:general", {});

chatInput.on("keypress", event => {
  if (event.keyCode === 13) {
    chan.push("send_message", {text: chatInput.val(), channel: "general"});
    chatInput.val("");
  }
})

chan.on("message_sent", payload => {
  messagesContainer.append(`<br/><time>${timestamp()}</time> <strong>${payload.user}</strong> ${payload.text}`);
})

chan.join().receive("ok", chan => {
  console.log("Connected");
})

let App = {
}

export default App
