module Lycantulul
  class Statistics

    def self.get_stats(stat)
      stats = ["Statistik #{stat}"]
      case stat
      when '/stats'
        stats << "Current stats:"
        stats << Time.now.utc.to_s
        stats << ''
        stats << "Players registered: #{Lycantulul::RegisteredPlayer.count}"
        stats << "Last 24|4|1 hours: #{Lycantulul::RegisteredPlayer.where(:created_at.gte => 24.hours.ago).count} | #{Lycantulul::RegisteredPlayer.where(:created_at.gte => 4.hours.ago).count} | #{Lycantulul::RegisteredPlayer.where(:created_at.gte => 1.hour.ago).count}"
        stats << "Blocking players: #{Lycantulul::RegisteredPlayer.where(blocked: true).count}"
        stats << ''
        stats << "Groups registered: #{Lycantulul::Group.count}"
        stats << "Last 24|4|1 hours: #{Lycantulul::Group.where(:created_at.gte => 24.hours.ago).count} | #{Lycantulul::Group.where(:created_at.gte => 4.hours.ago).count} | #{Lycantulul::Group.where(:created_at.gte => 1.hour.ago).count}"
        stats << ''
        stats << "Games created: #{Lycantulul::Game.count}"
        stats << "Last 24|4|1 hours: #{Lycantulul::Game.where(:created_at.gte => 24.hours.ago).count} | #{Lycantulul::Game.where(:created_at.gte => 4.hours.ago).count} | #{Lycantulul::Game.where(:created_at.gte => 1.hour.ago).count}"
        stats << ''
        stats << "Ranked games played: #{g = Lycantulul::Group.all.sum(&:game)}"
        stats << "Werewolf victory: #{w = Lycantulul::Group.all.sum(&:werewolf_victory)} (#{"%.2f\%" % (w * 100.0 / g)})"
        stats << "Villager victory: #{v = Lycantulul::Group.all.sum(&:village_victory)} (#{"%.2f\%" % (v * 100.0 / g)})"
        stats << ''
        stats << "Games waiting: #{Lycantulul::Game.waiting.count}"
        stats << "Games running: #{Lycantulul::Game.running.count}"
      when '/stats_role'
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
          stats << "Round #{g.round}, #{g.living_players.count}/#{g.players.count} alive"
          g.players.each do |y|
            stats << "#{y.full_name} @#{y.username}"
          end
          stats << ''
        end
      when '/stats_player'
        Lycantulul::RegisteredPlayer.all.sort_by(&:game).reverse.each do |x|
          stats << "#{"%3d" % x.game} #{x.first_name}"
        end
      when '/stats_group'
        Lycantulul::Group.all.sort_by(&:game).reverse.each do |x|
          stats << "#{"%3d" % x.game} #{x.title}"
        end
      end

      stats = stats.join("\n")[0...4000]
      stats
    end
  end
end
