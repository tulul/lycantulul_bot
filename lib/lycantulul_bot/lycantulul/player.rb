module Lycantulul
  class Player
    include Mongoid::Document
    include Mongoid::Locker
    include Mongoid::Timestamps

    field :user_id, type: Integer
    field :first_name, type: String
    field :full_name, type: String
    field :username, type: String
    field :role, type: Integer, default: Lycantulul::Game::VILLAGER
    field :alive, type: Boolean, default: true
    field :ready, type: Boolean, default: false
    field :abstain, type: Integer, default: 0

    index({ user_id: 1 })
    index({ full_name: 1 })

    belongs_to :game, class_name: 'Lycantulul::Game', index: true

    ABSTAIN_LIMIT = 3

    default_scope -> { order_by(full_name: :asc) }

    def self.with_id(user_id)
      self.find_by(user_id: user_id)
    end

    def self.without_id(id)
      self.where(:user_id.nin => id)
    end


    def self.with_name(name)
      self.find_by(full_name: name) || self.find_by(first_name: name) || self.find_by(username: name)
    end

    def self.with_role(role)
      self.where(role: role)
    end

    def self.without_role(role)
      self.where(:role.nin => role)
    end

    def self.alive
      self.where(alive: true)
    end

    def self.dead
      self.where(alive: false)
    end

    def self.abstain
      self.where(:abstain.gte => ABSTAIN_LIMIT)
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
      self.with_lock(wait: true) do
        self.role = Lycantulul::Game::VILLAGER
        self.alive = true
        self.save
      end
    end

    def kill
      self.with_lock(wait: true) do
        self.update_attribute(:alive, false)
      end
    end

    def revive
      self.with_lock(wait: true) do
        self.update_attribute(:alive, true)
      end
    end

    def assign(role)
      self.with_lock(wait: true) do
        self.update_attribute(:role, role)
      end
    end

    def inc_abstain
      self.with_lock(wait: true) do
        self.inc(abstain: 1)
      end
    end
  end
end
