import {Socket} from "phoenix"

let timestamp = function() {
  let time = new Date();
  return [time.getHours(), time.getMinutes(), time.getSeconds()]
           .map(n => ("0" + n).slice(-2)).join(':');
}

let getChannelPane = function(channel) {
  return $messages.find(`.pane[data-channel=${channel}]`);
};

let addChannel = function(channel) {
  var $channel = $(`
    <li class="list-group-item" data-channel="${channel.name}">
      #${channel.name}
    </li>`);

  if (channel.name == currentChannel) { $channel.addClass('active'); }

  $channel.click(event => {
    let $self = $(event.target);
    let channel = $self.data('channel');
    currentChannel = channel.name;
    $messages.find('.pane').addClass('hidden');
    getChannelPane(channel).removeClass('hidden');
    $self.siblings().removeClass('active');
    $self.addClass('active');
  });

  $channelsList.append($channel);

  var $pane = $(`<div class="pane" data-channel="${channel}"></div>`);
  if (channel.name != currentChannel) { $pane.addClass('hidden'); }
  $messages.append($pane);
}

let addUser = function(user) {
  let status = user.online ? 'online' : 'offline';
  $usersList.append(`
    <li class="list-group-item" data-user="${user.name}">
      <span class="indicator status-${status}"></span>
      ${user.name}
    </li>`);
}

let findUser = function(user) {
  return $usersList.find(`li[data-user="${user.name}"]`);
}

let toggleUser = function(user, status) {
  let $indicator = findUser(user).find('.indicator');
  $indicator.removeClass((idx, css) => {
    return (css.match(/(^|\s)status-\S+/g))
  });
  $indicator.addClass(`status-${status}`)
}

let currentChannel = 'general';
let channelUsers = {};
let username = localStorage.getItem("username");

if (username == null) {
  username = prompt("Enter your username");
  localStorage.setItem("username", username)
}

let socket = new Socket("/socket");
socket.connect({username: username});
let chan = socket.chan("rooms:_", {});

let $messages = $("#messages");
let $channelsList = $("#channels-list");
let $usersList = $("#users-list")
let $messageInput = $("#message-input");

$messageInput.on("keypress", event => {
  if (event.keyCode === 13) {
    chan.push("send_message", {
      text: $messageInput.val(),
      channel: currentChannel });

    $messageInput.val("");
  }
});

chan.on("message_sent", payload => {
  getChannelPane(payload.channel).append(`
    <br />
    <time>${timestamp()}</time>&nbsp;
    <strong>${payload.user}</strong>&nbsp;
    ${payload.text}`);

  $messages[0].scrollTop = $messages[0].scrollHeight;
});

chan.on("channels", payload => {
  $channelsList.empty();
  $.each(payload.channels, (_, channel) => { addChannel(channel) });
});

chan.on("channel_created", payload => {
  addChannel(payload.channel);
});

chan.on("users", payload => {
  $usersList.empty();
  $.each(payload.users, (_, user) => { addUser(user) });
});

chan.on("user_online", payload => {
  console.log(payload)
  if (findUser(payload.user).length) {
    toggleUser(payload.user, "online");
  } else {
    addUser(payload.user);
  }
});

chan.on("user_offline", payload => {
  console.log("user offline");
  console.log(payload);
  toggleUser(payload.user, "offline");
});

chan.join().receive("ok", _ => {
  console.log("Connected");
  chan.push("get_channels", {});
  chan.push("get_users", {});
});

let App = {};
export default App
