module LycantululBot
  class Group
    include Mongoid::Document
    include Mongoid::Locker
    include Mongoid::Timestamps

    field :group_id,                      type: Integer
    field :title,                         type: String

    field :voting_time,                   type: Integer
    field :night_time,                    type: Integer
    field :discussion_time,               type: Integer

    field :custom_roles,                  type: Array
    field :public_vote,                   type: Boolean, default: false

    field :game,                          type: Integer, default: 0

    field :werewolf_victory,              type: Integer, default: 0
    field :village_victory,               type: Integer, default: 0

    field :pending_time_id,               type: Integer, default: nil
    field :pending_time,                  type: String, default: nil

    store_in collection: 'lycantulul_groups'

    index({ group_id: 1 }, { unique: true })

    TIME_HASH = {
      'Malam Hari' => 'night_time',
      'Diskusi' => 'discussion_time',
      'Voting' => 'voting_time'
    }

    EXCEPTION = ['_id', 'group_id', 'voting_time', 'night_time', 'discussion_time']
    self.fields.keys.reject{ |field| EXCEPTION.include?(field) }.each do |field|
      define_method("inc_#{field}") do
        self.inc("#{field}" => 1)
      end
    end

    def self.get(message)
      group = self.find_or_create_by(group_id: message.chat.id)
      group.update_attribute(:title, message.chat.title)
      group
    end

    def statistics
      res = "Statistik Grup\n"
      res += "\n"
      res += "Main <b>#{self.game}</b>\n"
      res += "Kemenangan bagi Kejahatan <b>#{self.percentage(self.werewolf_victory)}</b>\n"
      res += "Kemenangan bagi Rakyat <b>#{self.percentage(self.village_victory)}</b>"
      res
    end

    def percentage(count)
      prc = game > 0 ? count * 100.0 / game : 0
      ("%.2f" % prc) + '%'
    end

    def time_setting_keyboard
      TIME_HASH.keys
    end

    def pending_reply(id)
      self.with_lock(wait: true) do
        self.update_attribute(:pending_time_id, id)
      end
    end

    def set_custom_time(time)
      self.with_lock(wait: true) do
        self.update_attribute(self.pending_time.to_sym, time)
        res = [TIME_HASH.key(self.pending_time).downcase, time]
        self.cancel_pending_time
        self.save
        res
      end
    end

    def cancel_pending_time
      self.with_lock(wait: true) do
        self.pending_time_id = nil
        self.pending_time = nil
        self.save
      end
    end

    def check_time_setting(time_string)
      self.with_lock(wait: true) do
        custom = TIME_HASH[time_string]
        self.pending_time = custom
        self.save
        custom
      end
    end
  end
end
