module Lycantulul
  class Game
    include Mongoid::Document

    VILLAGER = 0
    WEREWOLF = 1
    SEER = 2

    RESPONSE_OK = 0
    RESPONSE_INVALID = 1
    RESPONSE_DOUBLE = 2

    field :group_id, type: Integer
    field :players, type: Array, default: []
    field :night, type: Boolean, default: true
    field :waiting, type: Boolean, default: true
    field :finished, type: Boolean, default: false
    field :victim, type: Array, default: []
    field :votee, type: Array, default: []
    field :seen, type: Array, default: []

    index({ group_id: 1, finished: 1 })
    index({ finished: 1, waiting: 1, night: 1 })

    def self.create_from_message(message)
      res = self.create(
        group_id: message.chat.id
      )
      res.add_player(message.from)
    end

    def self.active_for_group(group)
      self.find_by(group_id: group.id, finished: false)
    end

    def add_player(user)
      return false if self.players.any?{ |pl| pl[:user_id] == user.id }

      new_player = {
        user_id: user.id,
        first_name: user.first_name,
        full_name: LycantululBot.get_full_name(user),
        role: VILLAGER,
        alive: true
      }
      self.players << new_player
      self.save
    end

    def add_victim(killer_id, victim)
      return RESPONSE_DOUBLE if self.victim.any?{ |vi| vi[:killer_id] == killer_id }
      return RESPONSE_INVALID unless self.killables.any?{ |ki| ki[:full_name] == victim }

      new_victim = {
        killer_id: killer_id,
        name: victim
      }
      self.victim << new_victim
      self.save
      RESPONSE_OK
    end

    def add_votee(voter_id, votee)
      return RESPONSE_DOUBLE if self.votee.any?{ |vo| vo[:voter_id] == voter_id }
      return RESPONSE_INVALID unless self.living_players.any?{ |lp| lp[:full_name] == votee }

      new_votee = {
        voter_id: voter_id,
        name: votee
      }
      self.votee << new_votee
      self.save
      RESPONSE_OK
    end

    def add_seen(seer_id, seen)
      return RESPONSE_DOUBLE if self.seen.any?{ |se| se[:seer_id] == seer_id }
      return RESPONSE_INVALID unless self.living_players.any?{ |lp| lp[:full_name] == seen }

      new_seen = {
        seer_id: seer_id,
        name: seen
      }
      self.seen << new_seen
      self.save
      RESPONSE_OK
    end

    def assign_role(player, role)
      self.players.each_with_index do |pl, idx|
        if pl[:user_id] == player[:user_id]
          self.players[idx][:role] = role
          LycantululBot.log("assigning #{get_role(role)} to #{pl[:full_name]}")
          break
        end
      end
      self.save
    end

    def start
      self.update_attribute(:waiting, false)
      assign(WEREWOLF)
      assign(SEER)
    end

    def finish
      self.update_attribute(:finished, true)
    end

    def assign(role)
      role_count(role).times do
        pl = -1
        loop do
          pl = self.players.sample
          break if pl[:role] == VILLAGER
        end
        assign_role(pl, role)
      end
    end

    def kill_victim
      vc = self.victim.group_by{ |vi| vi[:name] }.map{ |k, v| [k, v.count] }.sort_by{ |vi| vi[1] }.compact.reverse
      LycantululBot.log(vc.to_s)
      self.update_attribute(:victim, [])
      self.update_attribute(:night, false)

      if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
        victim_name = vc[0][0]
        self.players.each_with_index do |vi, idx|
          if vi[:full_name] == victim_name
            self.players[idx][:alive] = false
            self.save
            LycantululBot.log("#{victim_name} is mauled (from GAME)")
            return [self.players[idx][:user_id], self.players[idx][:full_name], self.get_role(self.players[idx][:role])]
          end
        end
      else
        return nil
      end
    end

    def kill_votee
      vc = self.votee.group_by{ |vo| vo[:name] }.map{ |k, v| [k, v.count] }.sort_by{ |vo| vo[1] }.reverse
      LycantululBot.log(vc.to_s)
      self.update_attribute(:votee, [])
      self.update_attribute(:night, true)

      if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
        votee_name = vc[0][0]
        self.players.each_with_index do |vi, idx|
          if vi[:full_name] == votee_name
            self.players[idx][:alive] = false
            self.save
            LycantululBot.log("#{votee_name} is executed (from GAME)")
            return [self.players[idx][:user_id], self.players[idx][:full_name], self.get_role(self.players[idx][:role])]
          end
        end
      else
        return nil
      end
    end

    def enlighten_seer
      vc = self.seen[0]
      LycantululBot.log(vc.to_s)
      self.update_attribute(:seen, [])

      return nil unless self.living_seers[0] && self.living_seers[0][:alive]

      if vc
        seen_name = vc[:name]
        self.players.each_with_index do |vi, idx|
          if vi[:alive] && vi[:full_name] == seen_name
            LycantululBot.log("#{seen_name} is seen (from GAME)")
            return [self.players[idx][:full_name], self.get_role(self.players[idx][:role])]
          end
        end
      end

      nil
    end

    def active_werewolf_with_victim?(player_id, victim_name)
      self.living_werewolves.any?{ |lw| lw[:user_id] == player_id } && self.killables.any?{ |kl| kl[:full_name] == victim_name }
    end

    def active_voter?(player_id, votee_name)
      self.living_players.any?{ |lp| lp[:user_id] == player_id } && self.living_players.any?{ |lp| lp[:full_name] == votee_name }
    end

    def active_seer?(player_id, seen_name)
      self.living_players.any?{ |lp| lp[:user_id] == player_id } && self.living_players.any?{ |lp| lp[:full_name] == seen_name }
    end

    def list_players
      liv_count = self.living_players_count
      ded_count = self.player_count - liv_count

      res = "Masi idup: #{liv_count} makhluk\n"

      if self.finished
        res += self.living_players.sort_by{ |lp| lp[:full_name] }.map{ |lp| "#{lp[:full_name]} - #{self.get_role(lp[:role])}" }.join("\n")
      else
        res += self.living_players.sort_by{ |lp| lp[:full_name] }.map{ |lp| lp[:full_name] }.join("\n")
      end

      res += "\n\n"
      res += "Udah mati: #{ded_count} makhluk\n"
      res += (self.players - self.living_players).sort_by{ |lp| lp[:full_name] }.map{ |lp| "#{lp[:full_name]} - #{self.get_role(lp[:role])}" }.join("\n")

      if self.waiting?
        res += "\n\n/ikutan yuk pada~"
      end

      res
    end

    def get_role(role)
      case role
      when VILLAGER
        'Warga kampung'
      when WEREWOLF
        'GGS'
      when SEER
        'Tukang intip'
      end
    end

    def role_count(role)
      case role
      when WEREWOLF
        (res = $redis.get('lycantulul::werewolf_divisor')) ? (self.players.size / res.to_i) + 1 : 1
      when SEER
        1
      end
    end

    def player_count
      self.players.size
    end

    def living_werewolves
      self.players.select do |pl|
        pl[:role] == WEREWOLF && pl[:alive]
      end
    end

    def living_seers
      self.players.select do |pl|
        pl[:role] == SEER && pl[:alive]
      end
    end

    def living_players
      self.players.select{ |pl| pl[:alive] }
    end

    def killables
      self.players.select do |pl|
        pl[:role] != WEREWOLF && pl[:alive]
      end
    end

    def victim_count
      self.victim.size
    end

    def votee_count
      self.votee.size
    end

    def seen_count
      self.seen.size
    end

    def living_werewolves_count
      self.living_werewolves.size
    end

    def living_seers_count
      self.living_seers.size
    end

    def living_players_count
      self.living_players.size
    end

    def killables_count
      self.killables.size
    end
  end
end
