class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def generate_response(message_content, conversation_history = [])
    messages = build_conversation(message_content, conversation_history)

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        max_tokens: 1000,
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    "I apologize, but I'm experiencing technical difficulties. Please try again later."
  end

  def generate_streaming_response(message_content, conversation_history = [], &block)
    messages = build_conversation(message_content, conversation_history)

    @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        max_tokens: 1000,
        temperature: 0.7,
        stream: proc do |chunk, _bytesize|
          content = chunk.dig("choices", 0, "delta", "content")
          block.call(content) if content && block_given?
        end
      }
    )
  rescue => e
    Rails.logger.error "OpenAI streaming error: #{e.message}"
    block.call("I apologize, but I'm experiencing technical difficulties. Please try again later.") if block_given?
  end

  private

  def build_conversation(message_content, conversation_history)
    messages = [
      {
        role: "system",
        content: "You are a helpful AI assistant for Nisk Chat. Provide clear, concise, and helpful responses."
      }
    ]

    # Add conversation history
    conversation_history.each do |msg|
      messages << {
        role: msg.role,
        content: msg.content
      }
    end

    # Add current message
    messages << {
      role: "user",
      content: message_content
    }

    messages
  end
end