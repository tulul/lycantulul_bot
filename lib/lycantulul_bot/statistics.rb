module LycantululBot
  class Statistics

    def self.get_stats(stat)
      stats = ["Statistik #{stat}"]
      case stat
      when '/stats'
        stats << "Current stats:"
        stats << Time.now.utc.to_s
        stats << ''
        stats << "Players registered: #{RegisteredPlayer.count}"
        stats << "Last 24|4|1 hours: #{RegisteredPlayer.where(:created_at.gte => 24.hours.ago).count} | #{RegisteredPlayer.where(:created_at.gte => 4.hours.ago).count} | #{RegisteredPlayer.where(:created_at.gte => 1.hour.ago).count}"
        stats << "Blocking players: #{RegisteredPlayer.where(blocked: true).count}"
        stats << ''
        stats << "Groups registered: #{Group.count}"
        stats << "Last 24|4|1 hours: #{Group.where(:created_at.gte => 24.hours.ago).count} | #{Group.where(:created_at.gte => 4.hours.ago).count} | #{Group.where(:created_at.gte => 1.hour.ago).count}"
        stats << ''
        stats << "Games created: #{Game.count}"
        stats << "Last 24|4|1 hours: #{Game.where(:created_at.gte => 24.hours.ago).count} | #{Game.where(:created_at.gte => 4.hours.ago).count} | #{Game.where(:created_at.gte => 1.hour.ago).count}"
        stats << ''
        stats << "Ranked games played: #{g = Group.all.sum(&:game)}"
        stats << "Werewolf victory: #{w = Group.all.sum(&:werewolf_victory)} (#{"%.2f\%" % (w * 100.0 / g)})"
        stats << "Villager victory: #{v = Group.all.sum(&:village_victory)} (#{"%.2f\%" % (v * 100.0 / g)})"
        stats << ''
        stats << "Games waiting: #{Game.waiting.count}"
        stats << "Games running: #{Game.running.count}"
      when '/stats_role'
        stats << "Role frequency statistics"

        sum = 0
        tot = {}
        RegisteredPlayer.all.each do |x|
          sum += x.game
          Game::ROLES.each do |role|
            tot[role] ||= 0
            tot[role] += x.send(role)
          end
        end

        g = Game.new
        tot.sort_by{ |_, v| v }.reverse.each do |role, count|
          stats << "<code>#{"%5.2f%" % (count * 100.0 / sum)}</code> #{g.get_role(g.class.const_get(role.upcase))}"
        end
      when '/stats_game_run'
        Game.running.each do |g|
          stats << "===== #{g.title.gsub(/[<>]/, '') rescue ''} ====="
          stats << "Round #{g.round}"
          stats << "#{g.living_players.count}/#{g.players.count} alive"
          stats << "#{g.killables.count} killables"
          stats << "N|D|V time: #{g.night_time}, #{g.discussion_time}, #{g.voting_time}"
          stats << ''
        end
      when '/stats_player_run'
        Game.running.each do |g|
          stats << "===== #{g.title.gsub(/[<>]/, '') rescue ''} ====="
          stats << "Round #{g.round}, #{g.living_players.count}/#{g.players.count} alive"
          g.players.each do |y|
            stats << "#{y.full_name} @#{y.username}"
          end
          stats << ''
        end
      when '/stats_player'
        RegisteredPlayer.all.sort_by(&:game).reverse.each do |x|
          stats << "#{"%3d" % x.game} #{x.full_name}"
        end
      when '/stats_group'
        Group.all.sort_by(&:game).reverse.each do |x|
          stats << "#{"%3d" % x.game} #{x.title.gsub(/[<>]/, '') rescue ''}"
        end
      end

      stats = stats.join("\n")[0...4000]
      stats
    end
  end
end
