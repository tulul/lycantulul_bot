module Lycantulul
  class Player
    include Mongoid::Document

    field :user_id, type: Integer
    field :first_name, type: String
    field :full_name, type: String
    field :username, type: String
    field :role, type: Integer, default: Lycantulul::Game::VILLAGER
    field :alive, type: Boolean, default: true

    index({ user_id: 1 })
    index({ full_name: 1 })

    belongs_to :game, class_name: 'Lycantulul::Game', index: true

    def self.with_id(user_id)
      self.find_by(user_id: user_id)
    end

    def self.with_name(name)
      self.find_by(full_name: name) || self.find_by(first_name: name) || self.find_by(username: name)
    end

    def self.with_role(role)
      self.where(role: role)
    end

    def self.without_role(role)
      self.where(:role.ne => role)
    end

    def self.alive
      self.where(alive: true)
    end

    def self.dead
      self.where(alive: false)
    end

    def self.create_player(user, game_id)
      self.create(
        user_id: user.id,
        game_id: game_id,
        first_name: user.first_name,
        full_name: get_full_name(user),
        username: user.username
      )
    end

    def self.get_full_name(user)
      fn = user.first_name
      user.last_name && fn += " #{user.last_name}"
      fn
    end

    def reset_state
      self.role = Lycantulul::Game::VILLAGER
      self.alive = true
      self.save
    end

    def kill
      self.update_attribute(:alive, false)
    end

    def revive
      self.update_attribute(:alive, true)
    end

    def assign(role)
      self.update_attribute(:role, role)
    end
  end
end
