module Lycantulul
  class Group
    include Mongoid::Document
    include Mongoid::Locker

    field :group_id,                      type: Integer

    field :voting_time,                   type: Integer
    field :night_time,                    type: Integer
    field :discussion_time,               type: Integer

    field :game,                          type: Integer, default: 0

    field :werewolf_victory,              type: Integer, default: 0
    field :village_victory,               type: Integer, default: 0

    index({ group_id: 1 }, { unique: true })

    EXCEPTION = ['_id', 'group_id', 'voting_time', 'night_time', 'discussion_time']
    self.fields.keys.reject{ |field| EXCEPTION.include?(field) }.each do |field|
      define_method("inc_#{field}") do
        self.inc("#{field}" => 1)
      end
    end

    def self.get(group_id)
      self.find_or_create_by(group_id: group_id)
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
  end
end
