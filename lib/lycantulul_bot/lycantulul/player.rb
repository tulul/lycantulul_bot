module Lycantulul
  class Player
    include Mongoid::Document

    field :user_id, type: Integer
    field :chat_id, type: Integer

    index({ user_id: 1 }, { unique: true })

    def self.create_from_message(message)
      user = message.from
      full_name = "#{user.first_name} #{user.last_name}"

      self.create(
        user_id: user.id,
        chat_id: message.chat.id,
      )
    end
  end
end
