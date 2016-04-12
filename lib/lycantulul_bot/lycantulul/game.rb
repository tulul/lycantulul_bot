module Lycantulul
  class Game
    include Mongoid::Document
    include Mongoid::Locker

    HIDDEN_ROLES = ['greedy_villager', 'useless_villager', 'super_necromancer', 'faux_seer', 'amnesty']
    IMPORTANT_ROLES = ['werewolf', 'seer', 'protector', 'necromancer', 'silver_bullet']
    DEFAULT_ROLES = ['villager']
    ROLES = HIDDEN_ROLES + IMPORTANT_ROLES + DEFAULT_ROLES

    ROLES.each_with_index do |role, value|
      const_set(role.upcase, value)
    end

    ['ok', 'invalid', 'double', 'skip'].each_with_index do |response, value|
      const_set("RESPONSE_#{response.upcase}", value)
    end

    NECROMANCER_SKIP = 'NDAK DULU DEH'

    field :group_id, type: Integer
    field :night, type: Boolean, default: true
    field :waiting, type: Boolean, default: true
    field :round, type: Integer, default: 0
    field :finished, type: Boolean, default: false
    field :victim, type: Array, default: []
    field :votee, type: Array, default: []
    field :seen, type: Array, default: []
    field :protectee, type: Array, default: []
    field :necromancee, type: Array, default: []
    field :super_necromancer_done, type: Boolean, default: false
    field :amnesty_done, type: Boolean, default: false

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

    def get_player(user_id)
      Lycantulul::RegisteredPlayer.get(user_id)
    end

    def add_player(user)
      return false if self.players.with_id(user.id)
      return self.players.create_player(user, self.id)
    end

    def remove_player(user)
      return false unless self.players.with_id(user.id)
      return self.players.with_id(user.id).destroy
    end

    # never call unless really needed (will ruin statistics)
    def restart
      self.with_lock(wait: true) do
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
    end

    def add_victim(killer_id, victim)
      self.with_lock(wait: true) do
        return RESPONSE_DOUBLE if self.victim.any?{ |vi| vi[:killer_id] == killer_id }
        return RESPONSE_INVALID unless valid_action?(killer_id, victim, 'werewolf')

        victim = self.killables.with_name(victim).full_name

        new_victim = {
          killer_id: killer_id,
          full_name: victim
        }
        self.victim << new_victim
        self.save
        RESPONSE_OK
      end
    end

    def add_votee(voter_id, votee)
      self.with_lock(wait: true) do
        return RESPONSE_DOUBLE if self.votee.any?{ |vo| vo[:voter_id] == voter_id }
        return RESPONSE_INVALID unless valid_action?(voter_id, votee, 'player')

        voter = self.living_players.with_id(voter_id)
        votee = self.living_players.with_name(votee).full_name

        vote_count =
          case voter.role
          when GREEDY_VILLAGER
            3
          when USELESS_VILLAGER
            0
          else
            1
          end

        vote_count.times do
          new_votee = {
            voter_id: voter_id,
            full_name: votee
          }
          self.votee << new_votee
        end

        self.save
        RESPONSE_OK
      end
    end

    def add_seen(seer_id, seen)
      self.with_lock(wait: true) do
        return RESPONSE_DOUBLE if self.seen.any?{ |se| se[:seer_id] == seer_id }
        return RESPONSE_INVALID unless valid_action?(seer_id, seen, 'seer')

        seen = self.living_players.with_name(seen).full_name

        new_seen = {
          seer_id: seer_id,
          full_name: seen
        }
        self.seen << new_seen
        self.save
        RESPONSE_OK
      end
    end

    def add_protectee(protector_id, protectee)
      self.with_lock(wait: true) do
        return RESPONSE_DOUBLE if self.protectee.any?{ |se| se[:protector_id] == protector_id }
        return RESPONSE_INVALID unless valid_action?(protector_id, protectee, 'protector')

        protectee = self.living_players.with_name(protectee).full_name

        new_protectee = {
          protector_id: protector_id,
          full_name: protectee
        }
        self.protectee << new_protectee
        self.save
        RESPONSE_OK
      end
    end

    def add_necromancee(necromancer_id, necromancee)
      self.with_lock(wait: true) do
        return RESPONSE_DOUBLE if self.necromancee.any?{ |se| se[:necromancer_id] == necromancer_id }
        return RESPONSE_INVALID unless valid_action?(necromancer_id, necromancee, 'necromancer') || valid_action?(necromancer_id, necromancee, 'super_necromancer')

        necromancee = self.dead_players.with_name(necromancee).full_name unless necromancee == NECROMANCER_SKIP

        new_necromancee = {
          necromancer_id: necromancer_id,
          full_name: necromancee
        }
        self.necromancee << new_necromancee
        self.save
        return RESPONSE_SKIP if necromancee == NECROMANCER_SKIP
        RESPONSE_OK
      end
    end

    def start
      self.with_lock(wait: true) do
        self.update_attribute(:waiting, false)
        ROLES.each do |role|
          assign(self.class.const_get(role.upcase))
        end
      end
    end

    def next_round
      self.with_lock(wait: true) do
        self.update_attribute(:round, self.round + 1)
      end
    end

    def assign(role)
      role_count(role).times do
        self.living_villagers.sample.assign(role)
        LycantululBot.log("assigning #{get_role(role)}")
      end
    rescue
    end

    def finish
      self.with_lock(wait: true) do
        self.update_attribute(:finished, true)
        self.players.each do |pl|
          player = self.get_player(pl.user_id)
          player.inc_game
          player.send("inc_#{ROLES[pl.role]}")
          if pl.alive
            player.inc_survived
          else
            player.inc_died
          end
        end
      end
    end

    def sort(array)
      array.group_by{ |vo| vo[:full_name] }.map{ |k, v| [k, v.count] }.sort_by{ |vo| vo[1] }.compact.reverse
    end

    def kill_victim
      self.with_lock(wait: true) do
        vc = self.sort(victim)
        LycantululBot.log(vc.to_s)
        self.update_attribute(:victim, [])
        self.update_attribute(:night, false)

        if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
          victim = self.living_players.with_name(vc[0][0])
          if !under_protection?(victim.full_name)
            victim.kill
            self.get_player(victim.user_id).inc_mauled
            self.get_player(victim.user_id).inc_mauled_first_day if self.round == 1
            LycantululBot.log("#{victim.full_name} is mauled (from GAME)")
            dead_werewolf =
              if victim.role == SILVER_BULLET
                ded = self.living_werewolves.sample
                ded.kill
                LycantululBot.log("#{ded.full_name} is killed because werewolves killed a silver bullet (from GAME)")
                ded
              end

            return [victim.user_id, victim.full_name, self.get_role(victim.role), dead_werewolf]
          else
            self.get_player(victim.user_id).inc_mauled_under_protection
            return nil
          end
        end

        nil
      end
    end

    def kill_votee
      self.with_lock(wait: true) do
        vc = self.sort(votee)
        LycantululBot.log(vc.to_s)
        self.update_attribute(:votee, [])
        self.update_attribute(:night, true)

        if vc.count == 1 || (vc.count > 1 && vc[0][1] > vc[1][1])
          votee = self.living_players.with_name(vc[0][0])
          if votee.role == AMNESTY && !self.amnesty_done
            self.update_attribute(:amnesty_done, true)
            self.get_player(votee.user_id).inc_executed_under_protection
          else
            votee.kill
            self.get_player(votee.user_id).inc_executed
            self.get_player(votee.user_id).inc_executed_first_day if self.round == 1
          end
          LycantululBot.log("#{votee.full_name} is executed (from GAME)")
          return votee
        end

        nil
      end
    end

    def enlighten_seer
      self.with_lock(wait: true) do
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
    end

    def protect_players
      self.with_lock(wait: true) do
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
    end

    def raise_the_dead
      self.with_lock(wait: true) do
        ss = self.necromancee
        LycantululBot.log(ss.to_s)
        self.update_attribute(:necromancee, [])

        res = []
        ss && ss.each do |vc|
          next if vc[:full_name] == NECROMANCER_SKIP
          necromancee = self.dead_players.with_name(vc[:full_name])
          necromancer = self.living_necromancers.with_id(vc[:necromancer_id]) || (!self.super_necromancer_done && self.living_super_necromancers.with_id(vc[:necromancer_id]))
          if necromancee && necromancer
            LycantululBot.log("#{necromancee.full_name} is raised from the dead by #{necromancer.full_name} (from GAME)")
            necromancee.revive
            self.get_player(necromancee.user_id).inc_revived
            if necromancer.role == SUPER_NECROMANCER
              self.update_attribute(:super_necromancer_done, true)
            else
              necromancer.kill
            end

            res << [necromancer, necromancee]
          end
        end

        res
      end
    end

    def round_finished?
      self.with_lock(wait: true) do
        res =
          self.victim.count == self.living_werewolves.count &&
          self.seen.count == self.living_seers.count &&
          self.protectee.count == self.living_protectors.count

        necromancer_count = self.living_necromancers.count
        necromancer_count += self.living_super_necromancers.count unless self.super_necromancer_done
        res &&  self.necromancee.count == necromancer_count
      end
    end

    def under_protection?(victim_name)
      self.protectee.any?{ |pr| pr[:full_name] == victim_name }
    end

    def valid_action?(actor_id, actee_name, role)
      self.with_lock(wait: true) do
        return false if role == 'super_necromancer' && self.super_necromancer_done

        actor = self.send("living_#{role.pluralize}").with_id(actor_id)

        actee =
          if role == 'werewolf'
            self.killables.with_name(actee_name)
          elsif role == 'necromancer' || role == 'super_necromancer'
            return true if actee_name == NECROMANCER_SKIP
            self.dead_players.with_name(actee_name)
          else
            self.living_players.with_name(actee_name)
          end

        actor && actee && actor.user_id != actee.user_id
      end
    end

    def list_players
      liv_count = self.living_players.count
      ded_count = self.dead_players.count

      res = "Masi idup: <b>#{liv_count} makhluk</b>\n"
      IMPORTANT_ROLES.each do |role|
        count = self.send("living_#{role.pluralize}").count
        count > 0 && res += "<i>#{count} #{self.get_role(self.class.const_get(role.upcase))}</i>\n"
      end

      if self.finished
        res += self.living_players.map{ |lp| "#{lp.full_name} - <i>#{self.get_role(lp.role)}</i>" }.sort.join("\n")
      else
        res += self.living_players.map(&:full_name).sort.join("\n")
      end

      if ded_count > 0
        res += "\n\n"
        res += "Udah mati: #{ded_count} makhluk\n"
        res += (self.dead_players).map{ |lp| "#{lp.full_name} - <i>#{self.get_role(lp.role)}</i>" }.sort.join("\n")
      end

      if self.waiting?
        res += "\n\n#{self.role_composition}" unless self.role_composition.empty?
        res += "\n/ikutan yuk pada~ yang udah ikutan jangan pada /gajadi"
      end

      res
    end

    def list_voting
      res = ''
      self.sort(votee).each do |votee|
        res += "#{votee[0]} - <b>#{votee[1]} suara</b>\n"
      end
      return 'Belum ada yang mulai voting. Mulai woy!' if res.empty?
      res
    end

    def get_role(role)
      case role
      when VILLAGER
        'Warga Kampung'
      when GREEDY_VILLAGER
        'Pak Raden'
      when USELESS_VILLAGER
        'Pak Ogah'
      when WEREWOLF
        'Tulul-Tulul Serigala'
      when SEER
        'Tukang Intip'
      when FAUX_SEER
        'Dukun'
      when PROTECTOR
        'Penjual Jimat'
      when NECROMANCER
        'Mujahid'
      when SUPER_NECROMANCER
        'Super Mujahid'
      when SILVER_BULLET
        'Pengidap Ebola'
      when AMNESTY
        'Anak Presiden'
      end
    end

    def get_task(role)
      case role
      when VILLAGER
        'Diam menunggu kematian. Seriously. Tapi bisa bantu-bantu yang lain lah sumbang suara buat bunuh para serigala, sekalian berdoa biar dilindungi sama penjual jimat kalo ada'
      when GREEDY_VILLAGER
        'Diam menunggu kematian. Tapi saat bertulul dan bermufakat untuk mengeksekusi, bobot suara lu adalah 3'
      when USELESS_VILLAGER
        'Diam menunggu kematian. Seriously kenapa lu harus ada sih? Bahkan saat voting eksekusi suara lu ga dianggep. Cian. Tiaja'
      when WEREWOLF
        "Tulul-Tulul Serigala -- BUNUH, BUNUH, BUNUH\n\nSetiap malam, bakal ditanya mau bunuh siapa (oiya, kalo misalnya ada serigala yang lain, kalian harus berunding soalnya ntar voting, kalo ga ada suara mayoritas siapa yang mau dibunuh, ga ada yang mati, ntar gua kasih tau kok pas gua tanyain)\n\nHati-hati, bisa jadi ada pengidap ebola di antara para warga kampung, kalo bunuh dia, 1 ekor serigala akan ikut mati"
      when SEER
        'Bantuin kemenangan para rakyat jelata dengan ngintipin ke rumah orang-orang. Pas ngintip ntar bisa tau mereka siapa sebenarnya. Tapi kalo misalnya yang mau diintip (atau elunya sendiri) mati dibunuh serigala, jadi gatau dia siapa sebenarnya :\'( hidup memang keras'
      when FAUX_SEER
        'Bantuin kemenangan para rakyat jelata, di mana setiap malam lu bakal dikasih tau role salah seorang pemain yang masih hidup secara random (ga jamin sih besoknya dikasih tau orang yang berbeda apa engga hahaha)'
      when PROTECTOR
        'Jualin jimat ke orang-orang. Orang yang dapet jimat akan terlindungi dari serangan para serigala. Ntar tiap malem ditanyain mau jual ke siapa (sebenernya ga jualan juga sih, ga dapet duit, maap yak). Hati-hati loh tapi, kalo lu jual jimat ke serigala bisa-bisa lu dibunuh dengan 25% kemungkinan, kecil lah, peluang lu buat dapet pasangan hidup masih lebih gede :)'
      when NECROMANCER
        'Menghidupkan kembali 1 orang mayat. Sebagai gantinya, lu yang bakal mati. Ingat, cuma ada 1 kesempatan! Dan jangan sampe lu malah dibunuh duluan sama serigala. Allaaaaahuakbar!'
      when SUPER_NECROMANCER
        'Menghidupkan kembali 1 orang mayat. Karena lu mujahid versi super, setelah menghidupkan seseorang, lu akan tetap hidup. Tenang, peran lu ga bakal dikasih tau ke siapa-siapa, hanya lu dan Allah yang tahu. Allaaaaahuakbar!'
      when SILVER_BULLET
        'Diam menunggu kematian. Tapi, kalo lu dibunuh serigala, 1 ekor serigalanya ikutan mati. Aduh itu kenapa kena ebola lu ga dikarantina aja sih'
      when AMNESTY
        'Diam menunggu kematian. Tapi, kalo lu dieksekusi oleh warga, lu bakal selamat (tapi cuma bisa sekali itu aja). Tiati aja sih malam berikutnya dibunuh serigala'
      end
    end

    def role_count(role, count = nil)
      count ||= self.players.count
      count -= Lycantulul::InputProcessorJob::MINIMUM_PLAYER.call
      case role
      when VILLAGER
        0
      when GREEDY_VILLAGER
        count > 3 && rand(100) < 35 ? 1 : 0 # [9-..., 1] 35% chance
      when USELESS_VILLAGER
        count > 5 && rand(100) < 70 ? 1 : 0 # [11-..., 1] 70% chance
      when WEREWOLF
        (count / 5) + 1 # [5-9, 1], [10-14, 2], ...
      when SEER
        ((count - 1) / 12) + 1 # [6-17, 1], [18-29, 2], ...
      when FAUX_SEER
        count > 6 && rand(100) < 75 ? 1 : 0 # [12-..., 1] 75% chance
      when PROTECTOR
        ((count - 3) / 14) + 1 # [8-21, 1], [22-35, 2], ...
      when NECROMANCER
        count > 6 ? 1 : 0 # [12-..., 1]
      when SUPER_NECROMANCER
        count > 10 && rand(100) < 25 ? 1 : 0 # [16-..., 1] 25% chance
      when SILVER_BULLET
        ((count - 9) / 10) + 1 # [14-23, 1], [24-33, 2], ...
      when AMNESTY
        count > 4 && rand(100) < 50 ? 1 : 0 # [10-..., 1] 50% chance
      end
    end

    def role_composition(count = nil)
      res = ''

      IMPORTANT_ROLES.each do |role|
        cur_count = role_count(self.class.const_get(role.upcase), count)
        cur_count > 0 && res += "<b>#{cur_count}</b> #{self.get_role(self.class.const_get(role.upcase))}\n"
      end
      res
    end

    def next_new_role
      res = 1
      current_comp = self.role_composition
      while current_comp == self.role_composition(self.players.count + res)
        res += 1
      end
      res
    end

    def living_players
      self.players.alive
    end

    ROLES.each do |role|
      define_method("living_#{role.pluralize}") do
        self.living_players.with_role(self.class.const_get(role.upcase))
      end
    end

    def killables
      self.living_players.without_role(WEREWOLF)
    end

    def pending_voters
      self.living_players - self.votee.map{ |a| self.players.with_id(a[:voter_id]) }
    end

    def dead_players
      self.players.dead
    end
  end
end
