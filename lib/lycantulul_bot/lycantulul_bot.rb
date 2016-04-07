class LycantululBot
  @@bot = nil
  @@round = 0

  MINIMUM_PLAYER = -> { (res = $redis.get('lycantulul::minimum_player')) ? res.to_i : 5 }
  DISCUSSION_TIME = -> { (res = $redis.get('lycantulul::discussion_time')) ? res.to_i : 60 }
  NIGHT_TIME = -> { (res = $redis.get('lycantulul::night_time')) ? res.to_i : 60 }
  VOTING_TIME = -> { (res = $redis.get('lycantulul::voting_time')) ? res.to_i : 60 }

  BROADCAST_ROLE = 0
  ROUND_START = 1
  WEREWOLF_KILL_BROADCAST = 2
  WEREWOLF_KILL_SUCCEEDED = 3
  WEREWOLF_KILL_FAILED= 4
  VOTING_START = 5
  VOTING_BROADCAST = 6
  VOTING_SUCCEEDED = 7
  VOTING_FAILED = 8
  ENLIGHTEN_SEER = 9

  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      @@bot = bot
      bot.listen do |message|
        log("incoming message from #{message.from.first_name}: #{message.text}")
        case message.text
        when '/start'
          if in_private?(message)
            send(message, 'Selamat datang! Ciee mau ikutan main werewolf. Pencet /daftar yak!')
          else
            wrong_room(message)
          end
        when /\/daftar/
          if in_private?(message)
            if check_player(message)
              send(message, 'Udah kedaftar wey!')
            else
              Lycantulul::Player.create_from_message(message)
              send(message, 'Terdaftar! Fave hun! Kalo mau ikutan main, balik ke grup tadi, terus pencet /ikutan')
            end
          else
            wrong_room(message)
          end
        when /\/bikin_baru/
          if in_group?(message)
            if check_game(message)
              send(message, 'Udah ada yang ngemulai gan tadi. /ikutan ae', true)
            else
              if check_player(message)
                Lycantulul::Game.create_from_message(message)
                send(message, "Oke yok maen! Yang mau /ikutan buruan yee. Kalo udah #{MINIMUM_PLAYER.call} pemain ntar bisa dimulai")
              else
                unregistered(message)
              end
            end
          else
            wrong_room(message)
          end
        when /\/batalin/
          if in_group?(message)
            if game = check_game(message)
              if game.waiting?
                game.finish
                send(message, "Sip batal maen :'(", true)
              else
                send(message, 'Udah mulai tjoy ga bisa batal enak aje', true)
              end
            else
              send(message, 'Batal apaan gan orang ga ada yang maen dah. Mending /bikin_baru', true)
            end
          else
            wrong_room(message)
          end
        when /\/ikutan/
          if in_group?(message)
            if game = check_game(message)
              if check_player(message)
                if game.waiting?
                  user = message.from
                  if game.add_player(user)
                    additional_text =
                      if game.player_count >= MINIMUM_PLAYER.call
                        "Udah bisa mulai btw, kalo mau /mulai_main yak. Atau enaknya nunggu makin rame lagi sih. Yok yang lain pada /ikutan"
                      else
                        "#{MINIMUM_PLAYER.call - game.player_count} orang lagi buruan /ikutan"
                      end

                    send(message, "Welcome to the game, #{user.first_name}!\n\nUdah #{game.player_count} orang nich~ #{additional_text}")
                  else
                    send(message, 'Duh udah masuk lu', true)
                  end
                else
                  send(message, 'Telat woy udah mulai!', true)
                end
              else
                unregistered(message)
              end
            else
              send(message, 'Ikutan apaan gan orang ga ada yang maen dah, kalo mau /bikin_baru', true)
            end
          else
            wrong_room(message)
          end
        when /\/mulai_main/
          if in_group?(message)
            if game = check_game(message)
              if game.waiting?
                if game.player_count >= MINIMUM_PLAYER.call
                  game.start
                  message_action(game, BROADCAST_ROLE)
                  message_action(game, ROUND_START)
                else
                  send(message, "Belom #{MINIMUM_PLAYER.call} orang! Tidak bisa~ Yang lain mending /ikutan dulu biar bisa mulai", true)
                end
              else
                send(message, 'Udah mulai tjoy dari tadi', true)
              end
            else
              send(message, 'Apa yang mau dimulai heh? /bikin_baru dulu!', true)
            end
          else
            wrong_room(message)
          end
        when /\/siapa_aja/
          if in_group?(message)
            if game = check_game(message)
              list_players(game)
            else
              send(message, 'Ga ada, orang ga ada yang maen. /bikin_baru gih', true)
            end
          else
            wrong_room(message)
          end
        else
          if in_private?(message)
            if game = check_werewolf_in_game(message)
              log('werewolf confirmed')
              case game.add_victim(message.from.id, message.text)
              when Lycantulul::Game::RESPONSE_OK
                message_action(game, WEREWOLF_KILL_BROADCAST, [message.from.first_name, message.text])
              when Lycantulul::Game::RESPONSE_INVALID
                send_kill_voting(game, message.chat.id)
              end

              check_round_finished(game, @@round)
            elsif game = check_voting(message)
              log('voter confirmed')
              case game.add_votee(message.from.id, message.text)
              when Lycantulul::Game::RESPONSE_OK
                send(message, 'Seeep')
                message_action(game, VOTING_BROADCAST, [message.from.first_name, message.from.username, message.text])
              when Lycantulul::Game::RESPONSE_INVALID
                full_name = get_full_name(message.from)
                send_voting(game.living_players, full_name, message.chat.id)
              end

              check_voting_finished(game, @@round)
            elsif game = check_seer(message)
              log('seer confirmed')
              case game.add_seen(message.from.id, message.text)
              when Lycantulul::Game::RESPONSE_OK
                send(message, 'Seeep. Tunggu ronde berakhir yak, kalo lu atau yang mau lu liat mati, ya jadi ga ngasih tau~')
              when Lycantulul::Game::RESPONSE_INVALID
                full_name = get_full_name(message.from)
                send_seer(game.living_players, full_name, message.chat.id)
              end

              check_round_finished(game, @@round)
            else
              send(message, 'WUT?')
            end
          end
        end
      end
    end
  end

  def self.message_action(game, action, aux = nil)
    case action
    when BROADCAST_ROLE
      log('game starts')
      opening = 'MULAI! MWA HA HA HA'
      opening += "\n\nJumlah pemain: #{game.player_count}\n"
      opening += "Jumlah peran:\n"
      opening += "Werewolf: #{game.role_count(Lycantulul::Game::WEREWOLF)}\n"
      opening += "Seer: #{game.role_count(Lycantulul::Game::SEER)}\n"
      opening += "Sisanya villager kampungan"
      send_to_player(game.group_id, opening)
      game.players.each do |pl|
        send_to_player(pl[:user_id], "Peran kamu kali ini adalah...... #{game.get_role(pl[:role])}!!!")
      end
    when ROUND_START
      group_chat_id = game.group_id
      @@round += 1
      log('new round')

      send_to_player(group_chat_id, "Malam pun tiba, para penduduk desa pun terlelap dalam gelap.\nNamun #{game.living_werewolves_count} werewolf culas diam-diam mengintai mereka yang tertidur pulas.\n\np.s.: Werewolf dan Seer buruan action via PM, cuma ada waktu #{NIGHT_TIME.call} detik!")
      log('enqueuing night job')
      Lycantulul::NightTimerJob.perform_in(NIGHT_TIME.call, game, @@round)

      game.living_werewolves.each do |ww|
        log("sending killing instruction to #{ww[:full_name]}")
        send_kill_voting(game, ww[:user_id])
      end

      lp = game.living_players
      game.living_seers.each do |se|
        send_seer(lp, se[:full_name], se[:user_id])
      end
    when WEREWOLF_KILL_BROADCAST
      lw = game.living_werewolves
      killer = aux[0]
      victim_name = aux[1]

      lw.each do |ww|
        log("broadcasting killing from to #{killer}")
        send_to_player(ww[:user_id], "#{killer} pengen si #{victim_name} modar")
      end
    when WEREWOLF_KILL_SUCCEEDED
      group_chat_id = game.group_id
      victim_chat_id = aux[0]
      victim_full_name = aux[1]

      log("#{victim_full_name} is killed by werewolves")
      send_to_player(victim_chat_id, 'MPOZ LO DIMAKAN WEREWOLF')
      send_to_player(group_chat_id, "GILS GILS GILS werewolf berhasil membunuh si #{victim_full_name} MPOZ MPOZ MPOZ")
      list_players(game)
      return if check_win(game)
      discuss(game)
    when WEREWOLF_KILL_FAILED
      group_chat_id = game.group_id
      log('no victim')
      send_to_player(group_chat_id, 'PFFFTTT CUPU BANGET WEREWOLF ga ada yang mati')
      list_players(game)
      discuss(game)
    when VOTING_START
      group_chat_id = game.group_id
      send_to_player(group_chat_id, "Udah ya tuduh-tuduhannya. Alangkah baiknya bermusyawarah dan bermufakat. Silakan voting siapa yang mau dieksekusi.\n\np.s.: semua wajib voting, waktunya cuma #{VOTING_TIME.call} detik. kalo ga ada suara mayoritas, ga ada yang mati")
      log('enqueuing voting job')
      Lycantulul::VotingTimerJob.perform_in(VOTING_TIME.call, game, @@round)

      livp = game.living_players
      livp.each do |lp|
        send_voting(livp, lp[:full_name], lp[:user_id])
      end
    when VOTING_BROADCAST
      group_chat_id = game.group_id
      voter_name = aux[0]
      voter_username = aux[1]
      votee_name = aux[2]

      voter = voter_username ? "@#{voter_username}" : voter_name

      log("#{voter} votes for #{votee_name}")
      send_to_player(group_chat_id, "#{voter} pengen mengeksekusi #{votee_name} mati aja woy lu ah")
    when VOTING_SUCCEEDED
      group_chat_id = game.group_id
      votee_chat_id = aux[0]
      votee_full_name = aux[1]

      log("voting succeeded, resulting in #{votee_full_name}'s death")
      send_to_player(votee_chat_id, 'MPOZ LO DIEKSEKUSI')
      send_to_player(group_chat_id, "Hasil musyawarah berbuah eksekusi si #{votee_full_name} MPOZ MPOZ MPOZ")
      list_players(game)
      return if check_win(game)
      message_action(game, ROUND_START)
    when VOTING_FAILED
      group_chat_id = game.group_id
      log('voting failed')
      send_to_player(group_chat_id, 'Musyawarah tidak membuahkan mufakat')
      list_players(game)
      message_action(game, ROUND_START)
    when ENLIGHTEN_SEER
      seer_id = game.living_seers[0][:user_id]
      seen_full_name = aux[0]
      seen_role = aux[1]

      log("sending #{seen_full_name}'s role to seer: #{seen_role}")
      send_to_player(seer_id, "Dengan kekuatan maksiat, peran si #{seen_full_name} pun terlihat: #{seen_role}")
    end
  end

  def self.discuss(game)
    send_to_player(game.group_id, "Silakan tuduh-tuduhan selama #{DISCUSSION_TIME.call} detik. Ntar gua tanya pada mau eksekusi siapa~")
    log('enqueuing discussion job')
    Lycantulul::DiscussionTimerJob.perform_in(DISCUSSION_TIME.call, game)
  end

  def self.send(message, text, reply = nil)
    options = {
      chat_id: message.chat.id,
      text: text,
    }
    options.merge!({ reply_to_message_id: message.message_id }) if reply
    log("sending #{text}")
    @@bot.api.send_message(options)
  end

  def self.send_to_player(chat_id, text, options = {})
    options.merge!({
      chat_id: chat_id,
      text: text
    })
    log("sending #{text}")
    @@bot.api.send_message(options)
  end

  def self.send_kill_voting(game, chat_id)
    lw = game.living_werewolves
    single_w = lw.size == 1
    killables = game.killables.map{ |kl| kl[:full_name] }

    kill_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: killables, resize_keyboard: true, one_time_keyboard: true)

    send_to_player(chat_id, "Daftar werewolf yang masih hidup: #{lw.map{ |w| w[:full_name] }.join(', ')}\n\np.s.: harus diskusi dulu. Jawaban semua werewolf dikumpulin dan yang paling banyak dibunuh. Kalo ga ada suara yang mayoritas, ga ada yang terbunuh yaa") unless single_w
    send_to_player(chat_id, 'Mau bunuh siapa?', reply_markup: kill_keyboard)
  end

  def self.send_voting(living_players, player_full_name, player_chat_id)
    log("sending voting to #{player_full_name}")
    vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [player_full_name], resize_keyboard: true, one_time_keyboard: true)
    send_to_player(player_chat_id, 'Ayo voting eksekusi siapa nih~', reply_markup: vote_keyboard)
  end

  def self.send_seer(living_players, seer_full_name, seer_chat_id)
    log("sending seer instruction to #{seer_full_name}")
    vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [seer_full_name], resize_keyboard: true, one_time_keyboard: true)
    send_to_player(seer_chat_id, 'Mau ngintip perannya siapa kak? :3', reply_markup: vote_keyboard)
  end

  def self.wrong_room(message)
    if in_private?(message)
      send(message, 'Di grup doang tjoy ini bisanya')
    elsif in_group?(message)
      send(message, 'PM mz mb! @lycantulul_bot', true)
    end
  end

  def self.unregistered(message)
    send(message, 'Lau belom terdaftar cuy. PM gua @lycantulul_bot terus /daftar, baru balik sini dan lakukan lagi apa yang mau lu lakukan tadi', true)
  end

  def self.list_players(game)
    send_to_player(game.group_id, game.list_players)
  end

  def self.check_game(message)
    Lycantulul::Game.active_for_group(message.chat)
  end

  def self.check_player(message)
    Lycantulul::Player.find_by(user_id: message.from.id)
  end

  def self.check_werewolf_in_game(message)
    log('checking werewolf votes')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.active_werewolf_with_victim?(message.from.id, message.text)
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_voting(message)
    log('checking voters')
    Lycantulul::Game.where(finished: false, waiting: false, night: false).each do |wwg|
      if wwg.active_voter?(message.from.id, message.text)
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_seer(message)
    log('checking seer')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.active_seer?(message.from.id, message.text)
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_round_finished(game, round, force = false)
    log("checking round finished #{round}")
    game.reload
    return unless round == @@round && game.night? && !game.waiting? && !game.finished?
    log('continuing')
    if force || (game.victim_count == game.living_werewolves_count && game.seen_count == game.living_seers_count)
      if killed = game.kill_victim
        message_action(game, WEREWOLF_KILL_SUCCEEDED, killed)
      else
        message_action(game, WEREWOLF_KILL_FAILED)
      end

      if seen = game.enlighten_seer
        message_action(game, ENLIGHTEN_SEER, seen)
      end
    end
  end

  def self.check_voting_finished(game, round, force = false)
    log("checking voting finished: #{round}")
    game.reload
    return unless round == @@round && !game.night? && !game.waiting? && !game.finished?
    log('continuing')
    if force || game.votee_count == game.living_players_count
      if killed = game.kill_votee
        message_action(game, VOTING_SUCCEEDED, killed)
      else
        message_action(game, VOTING_FAILED)
      end
    end
  end

  def self.check_win(game)
    log('checking win condition')
    game.reload
    win = false
    if game.living_werewolves_count == 0
      log('wereworlves ded')
      game.finish
      send_to_player(game.group_id, 'Dan permainan pun berakhir karena seluruh werewolf telah meninggal dunia. Mari doakan agar mereka tenang di sisi-Nya.')
      list_players(game)
      win = true
    elsif game.living_werewolves_count == game.killables_count || game.killables_count == 0
      log('villagers ded')
      game.finish
      send_to_player(game.group_id, 'Dan permainan pun berakhir karena werewolf telah memenangkan permainan. Semoga mereka terkutuk seumur hidup.')
      list_players(game)
      win = true
    end

    win
  end

  def self.get_full_name(user)
    fn = user.first_name
    user.last_name && fn += " #{user.last_name}"
    fn
  end

  def self.in_group?(message)
    message.chat.type == 'group'
  end

  def self.in_private?(message)
    message.chat.type == 'private'
  end

  def self.log(message)
    puts "log -- #{@@round} -- #{message}"
  end
end
