import {Socket} from "phoenix"

let chatInput         = $("#chat-input")
let messagesContainer = $("#messages")

let socket = new Socket("/socket")
socket.connect()
let chan = socket.chan("rooms:lobby", {})

chatInput.on("keypress", event => {
  if (event.keyCode === 13) {
    chan.push("new_msg", {body: chatInput.val()})
    chatInput.val("")
  }
})

chan.on("new_msg", payload => {
  messagesContainer.append(`<br/>[${Date()}] ${payload.body}`)
})

chan.join().receive("ok", chan => {
  console.log("Connected")
})

let App = {
}

export default App
