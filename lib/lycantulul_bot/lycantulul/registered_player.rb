module Lycantulul
  class RegisteredPlayer
    include Mongoid::Document
    include Mongoid::Locker
    include Mongoid::Timestamps

    field :user_id,                       type: Integer
    field :first_name,                    type: String
    field :last_name,                     type: String
    field :username,                      type: String

    field :game,                          type: Integer, default: 0

    field :mauled,                        type: Integer, default: 0
    field :mauled_first_day,              type: Integer, default: 0
    field :mauled_under_protection,       type: Integer, default: 0
    field :jester_safe,                   type: Integer, default: 0

    field :homeless_safe,                 type: Integer, default: 0
    field :homeless_mauled,               type: Integer, default: 0
    field :homeless_werewolf,             type: Integer, default: 0

    field :executed,                      type: Integer, default: 0
    field :executed_first_day,            type: Integer, default: 0
    field :executed_under_protection,     type: Integer, default: 0

    field :revived,                       type: Integer, default: 0
    field :survived,                      type: Integer, default: 0
    field :died,                          type: Integer, default: 0

    field :blocked,                       type: Boolean, default: false

    Lycantulul::Game::ROLES.each do |role|
      field role, type: Integer, default: 0
    end

    index({ user_id: 1 }, { unique: true })

    EXCEPTION = ['_id', 'user_id', 'first_name', 'last_name', 'username']
    self.fields.keys.reject{ |field| EXCEPTION.include?(field) }.each do |field|
      define_method("inc_#{field}") do
        self.inc("#{field}" => 1)
      end
    end

    def self.get(user_id)
      self.find_by(user_id: user_id)
    end

    def self.get_and_update(user)
      player = self.find_by(user_id: user.id)

      if player
        player.with_lock(wait: true) do
          player.first_name = user.first_name
          player.last_name = user.last_name
          player.username = user.username
          player.save if player.changed?
        end
      end

      player
    end

    def self.create_from_message(user)
      rp = self.get_and_update(user)
      rp ||= self.create(user_id: user.id, first_name: user.first_name, last_name: user.last_name, username: user.username)
      rp.update_attribute(:blocked, false)
      rp
    end

    def full_name
      res = self.first_name
      self.last_name && res += " #{self.last_name}"
      res
    end

    def statistics
      res = "Statistik <b>#{self.full_name}</b>\n"
      res += "\n"
      res += "Main <b>#{self.game}</b>\n"
      res += "Bertahan hidup <b>#{self.percentage(self.survived)}</b>\n"
      res += "Mati <b>#{self.percentage(self.died)}</b>\n"
      res += "\n"
      res += "Jumlah dibunuh TTS <b>#{self.mauled}</b>\n"
      res += "Hari pertama <b>#{self.mauled_first_day}</b>\n"
      res += "Dijimatin <b>#{self.mauled_under_protection}</b>\n"
      res += "Menghibur TTS sambil joget <b>#{self.jester_safe}</b>\n"
      res += "\n"
      res += "Ndak di rumah pas mau dibunuh TTS <b>#{self.homeless_safe}</b>\n"
      res += "Salah nebeng di rumah korban <b>#{self.homeless_mauled}</b>\n"
      res += "Salah nebeng di rumah TTS <b>#{self.homeless_werewolf}</b>\n"
      res += "\n"
      res += "Jumlah dieksekusi <b>#{self.executed}</b>\n"
      res += "Hari pertama <b>#{self.executed_first_day}</b>\n"
      res += "Dilindungi presiden <b>#{self.executed_under_protection}</b>\n"
      res += "\n"
      res += "Diidupin mujahid <b>#{self.revived}</b>\n"
      res += "\n"

      res += "Pembagian peran:\n"
      res += roles_statistics

      res
    end

    def percentage(count)
      prc = game > 0 ? count * 100.0 / game : 0
      ("%.2f" % prc) + '%'
    end

    def role_proportion(role)
      self.game > 0 ? self.send(role).to_f / self.game : 0
    end

    def roles_statistics
      sum = self.game
      tot = {}
      Lycantulul::Game::ROLES.each do |role|
        tot[role] ||= 0
        tot[role] += self.send(role)
      end

      g = Lycantulul::Game.new
      res = []
      tot.sort_by{ |_, v| v }.reverse.each do |role, count|
        prc = sum == 0 ? 0 : (count * 100.0 / sum)
        break if prc == 0
        res << "<code>#{"%5.2f%" % prc}</code> #{g.get_role(g.class.const_get(role.upcase))}"
      end

      res.join("\n")
    end
  end
end
