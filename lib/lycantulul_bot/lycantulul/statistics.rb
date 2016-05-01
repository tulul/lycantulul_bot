module Lycantulul
  class Statistics

    def self.get_stats(stat)
      stats = ["Statistik #{stat}"]
      case stat
      when '/stats'
        stats << "Current stats:"
        stats << Time.now.utc.to_s
        stats << ''
        stats << "Games started: #{Lycantulul::Game.count}"
        stats << "Ranked games played: #{g = Lycantulul::Group.all.sum(&:game)}"
        stats << "Werewolf victory: #{w = Lycantulul::Group.all.sum(&:werewolf_victory)} (#{"%.2f\%" % (w * 100.0 / g)})"
        stats << "Villager victory: #{v = Lycantulul::Group.all.sum(&:village_victory)} (#{"%.2f\%" % (v * 100.0 / g)})"
        stats << ''
        stats << "Registered players: #{Lycantulul::RegisteredPlayer.count}"
        stats << "Blocking players: #{Lycantulul::RegisteredPlayer.where(blocked: true).count}"
        stats << "Registered groups: #{Lycantulul::Group.count}"
        stats << ''
        stats << "Games waiting: #{Lycantulul::Game.waiting.count}"
        stats << "Games running: #{Lycantulul::Game.running.count}"
        stats << ''
        stats << "Role frequency statistics"

        sum = 0
        tot = {}
        Lycantulul::RegisteredPlayer.all.each do |x|
          sum += x.game
          Lycantulul::Game::ROLES.each do |role|
            tot[role] ||= 0
            tot[role] += x.send(role)
          end
        end

        g = Lycantulul::Game.new
        tot.sort_by{ |_, v| v }.reverse.each do |role, count|
          stats << "<code>#{"%5.2f%" % (count * 100.0 / sum)}</code> #{g.get_role(g.class.const_get(role.upcase))}"
        end
      when '/stats_player_run'
        Lycantulul::Game.running.each do |g|
          stats << "===== #{g.title} ====="
          stats << "Round #{g.round}"
          g.players.each do |y|
            stats << "#{y.full_name} @#{y.username}"
          end
          stats << ''
        end
      when '/stats_player'
        Lycantulul::RegisteredPlayer.all.sort_by(&:game).reverse.each do |x|
          stats << "<code>#{"%3d" % x.game}</code> #{x.first_name}"
        end
      when '/stats_group'
        Lycantulul::Group.all.sort_by(&:game).reverse.each do |x|
          stats << "<code>#{"%3d" % x.game}</code> #{x.title}"
        end
      end

      stats = stats.join("\n")[0...4000]
      stats
    end
  end
end
