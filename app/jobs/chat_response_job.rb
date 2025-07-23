class ChatResponseJob < ApplicationJob
  queue_as :default

  def perform(user_message_id)
    user_message = Message.find(user_message_id)
    
    # Get conversation history (last 10 messages)
    conversation_history = Message.where("id < ?", user_message.id)
                                 .order(:created_at)
                                 .last(10)

    openai_service = OpenaiService.new
    
    # Create placeholder AI message
    ai_message = Message.create!(
      role: 'assistant',
      content: "..."
    )

    # Broadcast placeholder message
    ActionCable.server.broadcast(
      "chat_channel",
      {
        message: ApplicationController.render(
          partial: "messages/message",
          locals: { message: ai_message }
        )
      }
    )

    # Generate streaming response
    full_response = ""
    openai_service.generate_streaming_response(
      user_message.content,
      conversation_history
    ) do |chunk|
      full_response += chunk if chunk
      
      # Update message content
      ai_message.update!(content: full_response)
      
      # Broadcast updated message
      ActionCable.server.broadcast(
        "chat_channel",
        {
          update_message: {
            id: ai_message.id,
            content: full_response
          }
        }
      )
    end

  rescue => e
    Rails.logger.error "ChatResponseJob error: #{e.message}"
    
    # Create error message
    error_message = Message.create!(
      role: 'assistant',
      content: "I apologize, but I'm experiencing technical difficulties. Please try again later."
    )

    ActionCable.server.broadcast(
      "chat_channel",
      {
        message: ApplicationController.render(
          partial: "messages/message",
          locals: { message: error_message }
        )
      }
    )
  end
end
