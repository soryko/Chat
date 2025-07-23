import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]

    connect() {
        console.log("Chat controller connected!")
        this.scrollToBottom()
    }

    resetForm(event) {
        if (event.detail.success) {
            this.inputTarget.value = ""
            this.inputTarget.focus()
            this.scrollToBottom()
        }
    }

    scrollToBottom() {
        const messagesContainer = document.getElementById("messages")
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight
        }
    }

    handleSubmit(event) {
        const message = this.inputTarget.value.trim()
        
        if (message === "") {
            event.preventDefault()
            return
        }

        this.inputTarget.disabled = true
        
        // Re-enable input after form submission
        setTimeout(() => {
            this.inputTarget.disabled = false
        }, 100)
    }
}