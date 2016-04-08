module Lycantulul
  class Game
    include Mongoid::Document

    VILLAGER = 0
    WEREWOLF = 1
    SEER = 2
    PROTECTOR = 3

    RESPONSE_OK = 0
    RESPONSE_INVALID = 1
    RESPONSE_DOUBLE = 2

    field :group_id, type: Integer
    field :night, type: Boolean, default: true
    field :waiting, type: Boolean, default: true
    field :finished, type: Boolean, default: false
    field :victim, type: Array, default: []
    field :votee, type: Array, default: []
    field :seen, type: Array, default: []
    field :protectee, type: Array, default: []

    index({ group_id: 1, finished: 1 })
    index({ finished: 1, waiting: 1, night: 1 })

    has_many :players, class_name: 'Lycantulul::Player'

    def self.create_from_message(message)
      res = self.create(group_id: message.chat.id)
      res.add_player(message.from)
    end

    def self.active_for_group(group)
      self.find_by(group_id: group.id, finished: false)
    end

    def add_player(user)
      return false if self.players.with_id(user.id)
      return self.players.create_player(user, self.id)
    end

    def remove_player(user)
      return false unless self.players.with_id(user.id)
      return self.players.with_id(user.id).destroy
    end

    def restart
      self.players.map(&:reset_state)
      self.night = true
      self.waiting = true
      self.finished = false
      self.victim = []
      self.votee = []
      self.seen = []
      self.protectee = []
      self.save
    end

    def add_victim(killer_id, victim)
      return RESPONSE_DOUBLE if self.victim.any?{ |vi| vi[:killer_id] == killer_id }
      return RESPONSE_INVALID unless valid_werewolf_with_victim?(killer_id, victim)

      new_victim = {
        killer_id: killer_id,
        full_name: victim
      }
      self.victim << new_victim
      self.save
      RESPONSE_OK
    end

    def add_votee(voter_id, votee)
      return RESPONSE_DOUBLE if self.votee.any?{ |vo| vo[:voter_id] == voter_id }
      return RESPONSE_INVALID unless valid_action?(voter_id, votee, 'player')

      new_votee = {
        voter_id: voter_id,
        full_name: votee
      }
      self.votee << new_votee
      self.save
      RESPONSE_OK
    end

    def add_seen(seer_id, seen)
      return RESPONSE_DOUBLE if self.seen.any?{ |se| se[:seer_id] == seer_id }
      return RESPONSE_INVALID unless valid_action?(seer_id, seen, 'seer')

      new_seen = {
        seer_id: seer_id,
        full_name: seen
      }
      self.seen << new_seen
      self.save
      RESPONSE_OK
    end

    def add_protectee(protector_id, protectee)
      return RESPONSE_DOUBLE if self.protectee.any?{ |se| se[:protector_id] == protector_id }
      return RESPONSE_INVALID unless valid_action?(protector_id, protectee, 'protector')

      new_protectee = {
        protector_id: protector_id,
        full_name: protectee
      }
      self.protectee << new_protectee
      self.save
      RESPONSE_OK
    end

    def start
      self.update_attribute(:waiting, false)
      assign(WEREWOLF)
      assign(SEER)
      assign(PROTECTOR)
    end

    def assign(role)
      role_count(role).times do
        self.living_villagers.sample.assign(role)
        LycantululBot.log("assigning #{get_role(role)}")
      end
    end

    def finish
      self.update_attribute(:finished, true)
    end

    def kill_victim
      vc = self.victim.group_by{ |vi| vi[:full_name] }.map{ |k, v| [k, v.count] }.sort_by{ |vi| vi[1] }.compact.reverse
      LycantululBot.log(vc.to_s)
      self.update_attribute(:victim, [])
      self.update_attribute(:night, false)

      if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
        victim = self.living_players.with_name(vc[0][0])
        if !under_protection?(victim.full_name)
          victim.kill
          LycantululBot.log("#{victim.full_name} is mauled (from GAME)")
          return [victim.user_id, victim.full_name, self.get_role(victim.role)]
        end
      end

      nil
    end

    def kill_votee
      vc = self.votee.group_by{ |vo| vo[:full_name] }.map{ |k, v| [k, v.count] }.sort_by{ |vo| vo[1] }.reverse
      LycantululBot.log(vc.to_s)
      self.update_attribute(:votee, [])
      self.update_attribute(:night, true)

      if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
        votee = self.living_players.with_name(vc[0][0])
        votee.kill
        LycantululBot.log("#{votee.full_name} is executed (from GAME)")
        return [votee.user_id, votee.full_name, self.get_role(votee.role)]
      end

      nil
    end

    def enlighten_seer
      ss = self.seen
      LycantululBot.log(ss.to_s)
      self.update_attribute(:seen, [])

      res = []
      ss && ss.each do |vc|
        seen = self.living_players.with_name(vc[:full_name])
        if seen && self.living_seers.with_id(vc[:seer_id])
          LycantululBot.log("#{seen.full_name} is seen (from GAME)")
          res << [seen.full_name, self.get_role(seen.role), vc[:seer_id]]
        end
      end

      res
    end

    def protect_players
      ss = self.protectee
      LycantululBot.log(ss.to_s)
      self.update_attribute(:protectee, [])

      return nil unless self.living_protectors.count > 0

      res = []
      ss && ss.each do |vc|
        protectee = self.living_players.with_name(vc[:full_name])
        if protectee.role == WEREWOLF && rand.round + rand.round == 0 # 25% ded if protecting werewolf
          ded = self.living_players.with_id(vc[:protector_id])
          ded.kill
          LycantululBot.log("#{ded.full_name} is killed because they protected werewolf (from GAME)")
          res << [ded.full_name, ded.user_id]
        end
      end

      res
    end

    def under_protection?(victim_name)
      self.protectee.any?{ |pr| pr[:full_name] == victim_name }
    end

    def valid_werewolf_with_victim?(killer_id, victim_name)
      self.living_werewolves.with_id(killer_id) && self.killables.with_name(victim_name)
    end

    def valid_action?(actor_id, actee_name, action)
      actor = eval("self.living_#{action}s").with_id(actor_id)
      actee = self.living_players.with_name(actee_name)
      actor && actee && actor.user_id != actee.user_id
    end

    def list_players
      liv_count = self.living_players.count
      ded_count = self.players.count - liv_count

      res = "Masi idup: #{liv_count} makhluk\n"

      if self.finished
        res += self.living_players.map{ |lp| "#{lp.full_name} - #{self.get_role(lp.role)}" }.sort.join("\n")
      else
        res += self.living_players.map(&:full_name).sort.join("\n")
      end

      if ded_count > 0
        res += "\n\n"
        res += "Udah mati: #{ded_count} makhluk\n"
        res += (self.players - self.living_players).map{ |lp| "#{lp.full_name} - #{self.get_role(lp.role)}" }.sort.join("\n")
      end

      if self.waiting?
        res += "\n\n/ikutan yuk pada~ yang udah ikutan jangan pada /gajadi"
      end

      res
    end

    def get_role(role)
      case role
      when VILLAGER
        'Warga kampung'
      when WEREWOLF
        'TTS'
      when SEER
        'Tukang intip'
      when PROTECTOR
        'Penjual jimat'
      end
    end

    def get_task(role)
      case role
      when VILLAGER
        'Diam menunggu kematian. Seriously. Tapi bisa bantu-bantu yang lain lah sumbang suara buat bunuh para serigala, sekalian berdoa biar dilindungi sama penjual jimat kalo ada'
      when WEREWOLF
        "Tulul-Tulul Serigala -- BUNUH, BUNUH, BUNUH\n\nSetiap malam, bakal ditanya mau bunuh siapa (oiya, kalo misalnya ada serigala yang lain, kalian harus berunding soalnya ntar voting, kalo ga ada suara mayoritas siapa yang mau dibunuh, ga ada yang mati, ntar gua kasih tau kok pas gua tanyain)"
      when SEER
        'Bantuin kemenangan para rakyat jelata dengan ngintipin ke rumah orang-orang. Pas ngintip ntar bisa tau mereka siapa sebenarnya. Tapi kalo misalnya yang mau diintip (atau elunya sendiri) mati dibunuh serigala, jadi gatau dia siapa sebenarnya :\'( hidup memang keras'
      when PROTECTOR
        'Jualin jimat ke orang-orang. Ntar tiap malem ditanyain mau jual ke siapa (sebenernya ga jualan juga sih, ga dapet duit, maap yak). Orang yang dapet jimat akan terlindungi dari serangan para serigala. Hati-hati loh tapi, kalo lu jual jimat ke serigala bisa-bisa lu dibunuh dengan 25% kemungkinan, kecil lah, peluang lu buat dapet pasangan hidup masih lebih gede :)'
      end
    end

    def role_count(role)
      base_count = self.players.count - LycantululBot::MINIMUM_PLAYER.call
      case role
      when WEREWOLF
        (base_count / 4) + 1 # [5-8, 1], [9-12, 2], ...
      when SEER
        (base_count / 8) + 1 # [5-12, 1], [13-20, 2], ...
      when PROTECTOR
        ((base_count - 3) / 9) + 1 # [8-16, 1], [17-25, 2], ...
      end
    end

    def living_players
      self.players.alive
    end

    def living_villagers
      self.living_players.with_role(VILLAGER)
    end

    def living_werewolves
      self.living_players.with_role(WEREWOLF)
    end

    def living_seers
      self.living_players.with_role(SEER)
    end

    def living_protectors
      self.living_players.with_role(PROTECTOR)
    end

    def killables
      self.living_players.without_role(WEREWOLF)
    end
  end
end
