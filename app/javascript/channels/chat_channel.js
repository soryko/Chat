import consumer from "./consumer"

consumer.subscriptions.create("ChatChannel", {
  connected() {
    console.log("Connected to ChatChannel")
  },

  disconnected() {
    console.log("Disconnected from ChatChannel")
  },

  received(data) {
    const messagesContainer = document.getElementById("messages")
    if (!messagesContainer) return

    if (data.message) {
      // Add new message
      const messageDiv = document.createElement('div')
      messageDiv.innerHTML = data.message
      messagesContainer.appendChild(messageDiv.firstElementChild)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }

    if (data.update_message) {
      // Update existing message content
      const messageElement = document.querySelector(`[data-message-id="${data.update_message.id}"]`)
      if (messageElement) {
        const contentElement = messageElement.querySelector('.message-content')
        if (contentElement) {
          contentElement.innerHTML = data.update_message.content.replace(/\n/g, '<br>')
        }
      }
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
});
