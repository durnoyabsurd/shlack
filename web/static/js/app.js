import {Socket} from "phoenix"

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
    currentChannel = channel;
    $messages.find('.pane').addClass('hidden');
    getChannelPane(channel).removeClass('hidden');
    $self.siblings().removeClass('active');
    $self.addClass('active');
  });

  $channelsList.append($channel);

  var $pane = $(`<div class="pane" data-channel="${channel.name}"></div>`);
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

let addMessage = function(message) {
  let time = new Date(Date.parse(message.inserted_at));
  let time_str = [time.getHours(), time.getMinutes(), time.getSeconds()]
                   .map(n => ("0" + n).slice(-2)).join(':');

  getChannelPane(message.channel).append(`
    <br />
    <time>${time_str}</time>&nbsp;
    <strong>${message.user}</strong>&nbsp;
    ${message.text}`);

  $messages[0].scrollTop = $messages[0].scrollHeight;
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

let lockInput = function(text) {
  $messageInput.attr('disabled', 'disabled').val(text);
}

let unlockInput = function(text) {
  $messageInput.removeAttr('disabled').val(text);
}

let currentChannel = 'general';
let channelUsers = {};
let username = localStorage.getItem("username");

if (username == null) {
  username = prompt("Enter your username");
  localStorage.setItem("username", username)
}

let $messages = $("#messages");
let $channelsList = $("#channels-list");
let $usersList = $("#users-list")
let $messageInput = $("#message-input");

lockInput("connecting…");
let socket = new Socket("/socket");
socket.connect({username: username});
let chan = socket.chan("rooms:_", {});

$messageInput.on("keypress", event => {
  if (event.keyCode === 13) {
    let text = $messageInput.val();
    let data = { text: text, channel: currentChannel };
    lockInput("sending…");
    chan.push("send_message", data)
        .receive("ok", _ => {
          unlockInput("");
        })
        .receive("error", (payload) => {
          unlockInput(text);
          alert(payload.reason);
        })
        .after(5000, () => {
          unlockInput(text);
          alert("Message sending timed out");
        });
  }
});

chan.on("incoming_message", payload => {
  addMessage(payload);
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
  if (findUser(payload.user).length) {
    toggleUser(payload.user, "online");
  } else {
    addUser(payload.user);
  }
});

chan.on("user_offline", payload => {
  toggleUser(payload.user, "offline");
});

chan.on("messages", payload => {
  console.log("messages");
  console.log(payload);
  let $pane = getChannelPane(payload.channel);
  $pane.empty();
  $.each(payload.messages, (_, message) => addMessage(message));
});

let putOnline = () => {
  $('.indicator-main').removeClass('status-offline').addClass('status-online');
}

let putOffline = () => {
  $('.indicator-main').removeClass('status-online').addClass('status-offline');
}

chan.join()
    .receive("ok", _ => {
      putOnline();
      unlockInput("");

      setInterval(() => {
        chan.push("ping")
            .receive("pong", putOnline)
            .after(3000, putOffline)
      }, 5000);
    })
    .receive("error", _ => {
      putOffline();
      alert("An error occurred while connecting to the server");
    })
    .after(5000, () => {
      putOffline();
      alert("Connection to the server timed out");
    });

let App = {};
export default App
