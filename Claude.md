# Project Context: Rails AI Chat App

This document outlines the current state, architecture, and setup instructions for the Rails AI Chat App. The goal is to provide a complete snapshot for any developer or AI assistant joining the project.

**Last Updated:** July 17, 2025

## 1. Project Overview

* **Goal:** A simple, single-page web application where a user can chat with an AI agent.
* **Core Functionality:**
    1.  The user sees a chat interface.
    2.  The user submits a message through a form.
    3.  The backend saves the user's message.
    4.  The backend calls an external AI service to get a response.
    5.  The backend saves the AI's response.
    6.  The UI updates in real-time to show both new messages without a full page reload.

## 2. Technology Stack

* **Backend:** Ruby on Rails 7+
* **Frontend JavaScript:** `esbuild` via the `jsbundling-rails` gem.
* **Frontend CSS:** Tailwind CSS via the `tailwindcss-rails` gem.
* **Frontend Framework:** Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, and Stimulus).
* **Database:** Default SQLite (as per standard Rails setup).
* **AI Integration:** Google Generative AI (Gemini Pro) via the `google-generative_ai` gem.

## 3. Current Status

The application is fully functional. A user can visit the root URL, send a message, and receive a response from the AI. The setup process encountered and resolved several common environment issues related to CSS and JavaScript bundling.

## 4. Key File Breakdown

Here are the most important files that have been created or modified.

#### `Gemfile` (relevant additions)
* The gem for connecting to the Google AI API.

```ruby
gem "google-generative_ai"
```

#### `config/routes.rb`
* Defines the root path to the chat interface and a POST endpoint for creating new messages.

```ruby
Rails.application.routes.draw do
  root "chat#index"
  post "chat", to: "chat#create"
end
```

#### `app/controllers/chat_controller.rb`
* Handles the main application logic: displaying the chat history and processing new messages.

```ruby
class ChatController < ApplicationController
  def index
    @messages = Message.order(:created_at)
  end

  def create
    user_message = Message.create(
      role: 'user',
      content: params[:message]
    )

    ai_service = AiAgentService.new
    ai_response_content = ai_service.get_response(user_message.content)

    ai_message = Message.create(
      role: 'assistant',
      content: ai_response_content
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "messages",
          partial: "messages/message",
          locals: { message: user_message }
        ) + turbo_stream.append(
          "messages",
          partial: "messages/message",
          locals: { message: ai_message }
        )
      end
    end
  end
end
```

#### `app/models/message.rb`
* The ActiveRecord model for storing messages in the database.

```ruby
class Message < ApplicationRecord
end
```

#### `app/services/ai_agent_service.rb`
* A service object to encapsulate the logic for communicating with the external AI API.

```ruby
require "google/generative_ai"

class AiAgentService
  def initialize
    api_key = Rails.application.credentials.google_api_key
    @client = Google::GenerativeAI::GenerativeModel.new(api_key: api_key, model_name: "gemini-1.5-flash")
  end

  def get_response(message_content)
    begin
      response = @client.generate_content(message_content)
      response.candidates.first.content.parts.first.text
    rescue => e
      Rails.logger.error "AI API Error: #{e.message}"
      "Sorry, I'm having trouble connecting to my brain right now."
    end
  end
end
```

#### `app/views/chat/index.html.erb`
* The main view file containing the chat window and the message input form.

```erb
<div class="max-w-3xl mx-auto my-10 p-6 bg-white rounded-lg shadow-xl" data-controller="chat">
  <h1 class="text-2xl font-bold mb-4">AI Chat Agent 🤖</h1>

  <div id="messages" class="mb-4 h-96 overflow-y-auto p-4 bg-gray-50 rounded border">
    <%= render @messages %>
  </div>

  <%= form_with url: "/chat", data: { action: "turbo:submit-end->chat#resetForm" } do |form| %>
    <div class="flex">
      <%= form.text_field :message,
            class: "flex-grow border rounded-l-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "Type your message...",
            autocomplete: "off",
            data: { chat_target: "input" } %>
      <%= form.submit "Send", class: "bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-r-lg" %>
    </div>
  <% end %>
</div>
```

#### `app/views/messages/_message.html.erb`
* The partial used to render each individual message, styled differently for the 'user' and 'assistant'.

```erb
<div class="mb-2 p-3 rounded-lg <%= message.role == 'user' ? 'bg-blue-100 text-right ml-auto' : 'bg-gray-200 text-left mr-auto' %> max-w-xl">
  <p class="text-sm"><strong><%= message.role.capitalize %></strong></p>
  <p><%= message.content %></p>
</div>
```

#### `app/javascript/controllers/chat_controller.js`
* A Stimulus controller to clear the text input after a message is sent.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  resetForm(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }
}
```

## 5. Database Schema

The `messages` table has the following structure:

* `id`: integer (primary key)
* `role`: string
* `content`: text
* `created_at`: datetime
* `updated_at`: datetime

## 6. Setup and Execution

1.  **Clone the repository.**
2.  **Install Ruby dependencies:** `bundle install`
3.  **Install JavaScript dependencies:** `yarn install`
4.  **Set up credentials:** Run `bin/rails credentials:edit` and add the `google_api_key`.
5.  **Create and migrate the database:** `rails db:create && rails db:migrate`
6.  **Run the development server:** `bin/dev`

## 7. Development History & Troubleshooting

The initial setup faced three main issues that were resolved:
1.  **`Sprockets::NotFound` error for `application.css`:** Fixed by changing the layout file to use `<%= stylesheet_link_tag "tailwind", ... %>`.
2.  **`esbuild not found` error:** Fixed by running `yarn install` to download JS dependencies.
3.  **`command failed with exit code 127` when running `bin/dev`:** Fixed by installing `yarn` globally (`npm install --global yarn`) and running `yarn install` again.

This indicates the development environment requires Node.js, Yarn, and Ruby to be correctly installed and available in the system's PATH.