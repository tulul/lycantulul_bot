module Lycantulul
  class Player
    include Mongoid::Document

    field :user_id, type: Integer

    index({ user_id: 1 }, { unique: true })

    def self.create_from_message(message)
      self.create(user_id: message.from.id)
    end
  end
end
