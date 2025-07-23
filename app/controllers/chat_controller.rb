class ChatController < ApplicationController
  def index
    @messages = Message.order(:created_at)
  end

  def create
    if params[:message].blank?
      redirect_to chat_index_path, alert: "Message cannot be empty"
      return
    end

    user_message = Message.new(
      role: 'user',
      content: params[:message].strip
    )

    if user_message.save
      # Broadcast user message immediately
      ActionCable.server.broadcast(
        "chat_channel",
        {
          message: render_to_string(
            partial: "messages/message",
            locals: { message: user_message }
          )
        }
      )

      # Generate AI response in background
      ChatResponseJob.perform_later(user_message.id)

      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to chat_index_path }
      end
    else
      redirect_to chat_index_path, alert: "Error: #{user_message.errors.full_messages.join(', ')}"
    end
  end
end
