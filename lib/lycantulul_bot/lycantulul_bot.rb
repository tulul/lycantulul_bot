class LycantululBot
  @@bot = nil

  MINIMUM_PLAYER = -> { (res = $redis.get('lycantulul::minimum_player')) ? res.to_i : 5 }
  NIGHT_TIME = -> { (res = $redis.get('lycantulul::night_time')) ? res.to_i : 90 }
  # multiply of 8 please
  VOTING_TIME = -> { (res = $redis.get('lycantulul::voting_time')) ? res.to_i : 160 }

  ALLOWED_DELAY = -> { (res = $redis.get('lycantulul::allowed_delay')) ? res.to_i : 20 }

  MAINTENANCE = -> { $redis.get('lycantulul::maintenance').to_i == 1 rescue nil }

  [
    'broadcast_role',
    'round_start',
    'werewolf_kill_broadcast',
    'werewolf_kill_succeeded',
    'werewolf_kill_failed',
    'voting_start',
    'voting_succeeded',
    'voting_failed',
    'enlighten_seer',
    'dead_protectors',
    'zombie_revived'
  ].each_with_index do |state, value|
    const_set(state.upcase, value)
  end

  def self.start(message)
        log("incoming message from #{message.from.first_name}: #{message.text}")

        if MAINTENANCE.call
          reply = in_group?(message)
          send(message, 'Lagi bermain bersama Ecchi-men Ryoman dan Nopak Jokowi', reply: reply)
        else
          if Time.now.to_i - message.date < ALLOWED_DELAY.call
            if new_member = message.new_chat_participant
              unless Lycantulul::RegisteredPlayer.find_by(user_id: new_member.id)
                name = new_member.username ? "@#{new_member.username}" : new_member.first_name
                send(message, "Welcome #{name}. PM aku @lycantulul_bot terus /start yaa~", reply: true)
              end
            end

            case message.text
            when '/start'
              if in_private?(message)
                if check_player(message)
                  send(message, 'Udah kedaftar wey!')
                else
                  Lycantulul::RegisteredPlayer.create_from_message(message)
                  send(message, 'Terdaftar! Lood Guck and Fave hun! Kalo mau ikutan main, balik ke grup, terus pencet /ikutan')
                end
              else
                wrong_room(message)
              end
            when /\/help/
              send(message, bot_help)
            when /\/bikin_baru/
              if in_group?(message)
                if check_game(message)
                  send(message, 'Udah ada yang ngemulai gan tadi. /ikutan ae', reply: true)
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
                    send(message, "Sip batal maen :'(", reply: true)
                  else
                    send(message, 'Udah mulai tjoy ga bisa batal enak aje', reply: true)
                  end
                else
                  send(message, 'Batal apaan gan orang ga ada yang maen dah. Mending /bikin_baru', reply: true)
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
                          if game.players.count >= MINIMUM_PLAYER.call
                            "Udah bisa mulai btw, kalo mau /mulai_main yak. Atau enaknya nunggu makin rame lagi sih. Yok yang lain pada /ikutan\n\nPembagian peran:\n#{game.role_composition}\nTambah <b>#{game.next_new_role}</b> orang lagi ada peran peran penting tambahan"
                          else
                            "#{MINIMUM_PLAYER.call - game.players.count} orang lagi buruan /ikutan"
                          end

                        send(message, "Welcome to the game, #{user.first_name}!\n\nUdah <b>#{game.players.count} orang</b> nich~ #{additional_text}", html: true)
                      else
                        send(message, 'Duh udah masuk lu', reply: true)
                      end
                    else
                      send(message, 'Telat woy udah mulai!', reply: true)
                    end
                  else
                    unregistered(message)
                  end
                else
                  send(message, 'Ikutan apaan gan orang ga ada yang maen dah, kalo mau /bikin_baru', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/gajadi/
              if in_group?(message)
                if game = check_game(message)
                  if check_player(message)
                    if game.waiting?
                      user = message.from
                      if game.remove_player(user)
                        if game.players.count == 0
                          game.finish
                          send(message, 'Bubar semua bubar! /bikin_baru lagi dong')
                        else
                          additional_text =
                            if game.players.count >= MINIMUM_PLAYER.call
                              'Ayo deh yang lain juga /ikutan, biar bisa /mulai_main'
                            else
                              "Orangnya jadi kurang kan. #{MINIMUM_PLAYER.call - game.players.count} orang lagi buruan /ikutan"
                            end

                          send(message, "Jangan /gajadi main dong #{user.first_name} :( /ikutan lagi plis :(\n#{additional_text}")
                        end
                      else
                        send(message, 'Jangan bohong kamu ya. Kamu kan ndak /ikutan', reply: true)
                      end
                    else
                      send(message, 'Udah mulai sih, ga boleh kabur', reply: true)
                    end
                  else
                    unregistered(message)
                  end
                else
                  send(message, 'Ga jadi what? /bikin_baru dulu', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/mulai_main/
              if in_group?(message)
                if game = check_game(message)
                  if game.waiting?
                    if game.players.count >= MINIMUM_PLAYER.call
                      game.start
                      message_action(game, BROADCAST_ROLE)
                      message_action(game, ROUND_START)
                    else
                      send(message, "Belom #{MINIMUM_PLAYER.call} orang! Tidak bisa~ Yang lain mending /ikutan dulu biar bisa mulai", reply: true)
                    end
                  else
                    send(message, 'Udah mulai tjoy dari tadi', reply: true)
                  end
                else
                  send(message, 'Apa yang mau dimulai heh? /bikin_baru dulu!', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/siapa_aja/
              if in_group?(message)
                if game = check_game(message)
                  list_players(game)
                else
                  send(message, 'Ga ada, orang ga ada yang maen. /bikin_baru gih', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/hasil_voting/
              if in_group?(message)
                if game = check_game(message)
                  unless game.waiting?
                    unless game.night?
                      list_voting(game)
                    else
                      send(message, 'Masih malem, belom mulai voting', reply: true)
                    end
                  else
                    send(message, 'Belom /mulai_main', reply: true)
                  end
                else
                  send(message, 'No game coy. /bikin_baru dulu', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/panggil_semua/
              if in_group?(message)
                if game = check_game(message)
                  summon(game, :all)
                else
                  send(message, 'Ga ada yang lagi main, /bikin_baru dulu', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/panggil_yang_idup/
              if in_group?(message)
                if game = check_game(message)
                  summon(game, :alive)
                else
                  send(message, 'Ga ada yang lagi main, /bikin_baru dulu', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/panggil_yang_belom_voting/
              if in_group?(message)
                if game = check_game(message)
                  unless game.waiting?
                    unless game.night?
                      summon(game, :voting)
                    else
                      send(message, 'Masih malem, belom mulai voting', reply: true)
                    end
                  else
                    send(message, 'Belom /mulai_main', reply: true)
                  end
                else
                  send(message, 'No game coy. /bikin_baru dulu', reply: true)
                end
              else
                wrong_room(message)
              end
            when /\/ilangin_keyboard/
              if in_private?(message)
                keyboard = Telegram
                keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                send_to_player(message.chat.id, 'OK', reply_markup: keyboard)
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

                  check_round_finished(game, game.round)
                elsif game = check_voting(message)
                  log('voter confirmed')
                  case game.add_votee(message.from.id, message.text)
                  when Lycantulul::Game::RESPONSE_OK
                    send(message, 'Seeep')
                  when Lycantulul::Game::RESPONSE_INVALID
                    full_name = Lycantulul::Player.get_full_name(message.from)
                    send_voting(game.living_players, full_name, message.chat.id)
                  end

                  check_voting_finished(game, game.round)
                elsif game = check_seer(message)
                  log('seer confirmed')
                  case game.add_seen(message.from.id, message.text)
                  when Lycantulul::Game::RESPONSE_OK
                    send(message, 'Seeep. Tunggu ronde berakhir yak, kalo lu atau yang mau lu liat mati, ya jadi ga ngasih tau~')
                  when Lycantulul::Game::RESPONSE_INVALID
                    full_name = Lycantulul::Player.get_full_name(message.from)
                    send_seer(game.living_players, full_name, message.chat.id)
                  end

                  check_round_finished(game,game.round)
                elsif game = check_protector(message)
                  log('protector confirmed')
                  case game.add_protectee(message.from.id, message.text)
                  when Lycantulul::Game::RESPONSE_OK
                    send(message, 'Seeep')
                  when Lycantulul::Game::RESPONSE_INVALID
                    full_name = Lycantulul::Player.get_full_name(message.from)
                    send_protector(game.living_players, full_name, message.chat.id)
                  end

                  check_round_finished(game, game.round)
                elsif game = check_necromancer(message)
                  log('necromancer confirmed')
                  case game.add_necromancee(message.from.id, message.text)
                  when Lycantulul::Game::RESPONSE_OK
                    send(message, 'Seeep. Kamu sungguh berjasa :\') Tapi kalo kamu dibunuh serigala, gajadi deh :\'(')
                  when Lycantulul::Game::RESPONSE_SKIP
                    send(message, 'Okay, sungguh bijaksana')
                  when Lycantulul::Game::RESPONSE_INVALID
                    send_necromancer(game.dead_players, message.chat.id)
                  end

                  check_round_finished(game, game.round)
                else
                  send(message, 'WUT?')
                end
              end
            end
          else
            log('stale message. purged')
          end
        end
  rescue StandardError => e
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    retry
  end

  def self.message_action(game, action, aux = nil)
    case action
    when BROADCAST_ROLE
      log('game starts')
      opening = 'MULAI! MWA HA HA HA'
      opening += "\n\nJumlah pemain: <b>#{game.players.count} makhluk</b>\n"
      opening += "Jumlah peran penting:\n"
      opening += game.role_composition
      opening += "\nSisanya villager kampungan ndak penting"
      send_to_player(game.group_id, opening, parse_mode: 'HTML')
      game.players.each do |pl|
        send_to_player(pl[:user_id], "Peran kamu kali ini adalah......#{game.get_role(pl[:role])}!!!\n\nTugasmu: #{game.get_task(pl[:role])}")
      end
    when ROUND_START
      group_chat_id = game.group_id
      game.next_round
      log('new round')

      send_to_player(group_chat_id, "Malam pun tiba, para penduduk desa pun terlelap dalam gelap.\nNamun #{game.living_werewolves.count} serigala tulul dan culas diam-diam mengintai mereka yang tertidur pulas.\n\np.s.: Buruan action via PM, cuma ada waktu <b>#{NIGHT_TIME.call} detik</b>! Kecuali warga kampung, diam aja menunggu kematian ya", parse_mode: 'HTML')
      log('enqueuing night job')
      # Lycantulul::NightTimerJob.perform_in(NIGHT_TIME.call, game, @@round)

      game.living_werewolves.each do |ww|
        log("sending killing instruction to #{ww[:full_name]}")
        send_kill_voting(game, ww[:user_id])
      end

      lp = game.living_players
      game.living_seers.each do |se|
        send_seer(lp, se[:full_name], se[:user_id])
      end

      game.living_protectors.each do |se|
        send_protector(lp, se[:full_name], se[:user_id])
      end

      dp = game.dead_players
      game.living_necromancers.each do |se|
        send_necromancer(dp, se[:user_id])
      end

      !game.super_necromancer_done && game.living_super_necromancers.each do |se|
        send_necromancer(dp, se[:user_id])
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
      victim_role = aux[2]
      dead_werewolf = aux[3]

      log("#{victim_full_name} is killed by werewolves")
      send_to_player(victim_chat_id, 'MPOZ LO MATEK')
      send_to_player(group_chat_id, "GILS GILS GILS\nserigala berhasil memakan si #{victim_full_name}\nMPOZ MPOZ MPOZ\n\nTernyata dia itu #{victim_role}")

      if dead_werewolf
        send_to_player(dead_werewolf.user_id, 'MPOZ. Sial kan bunuh pengidap ebola, lu ikutan terjangkit. Mati deh')
        send_to_player(group_chat_id, "#{victim_full_name} yang ternyata mengidap ebola ikut menjangkiti seekor serigala #{dead_werewolf.full_name} yang pada akhirnya meninggal dunia. Mari berantas ebola dari muka bumi ini secepatnya!")
      end

      return if check_win(game)
      message_action(game, VOTING_START)
    when WEREWOLF_KILL_FAILED
      group_chat_id = game.group_id
      log('no victim')
      send_to_player(group_chat_id, 'PFFFTTT CUPU BANGET SERIGALA PADA, ga ada yang mati')
      message_action(game, VOTING_START)
    when VOTING_START
      group_chat_id = game.group_id
      send_to_player(group_chat_id, "Silakan bertulul dan bermufakat. Silakan voting siapa yang mau dieksekusi.\n\np.s.: semua wajib voting, waktunya cuma <b>#{VOTING_TIME.call} detik</b>. kalo ga ada suara mayoritas, ga ada yang mati", parse_mode: 'HTML')
      log('enqueuing voting job')
      # Lycantulul::VotingTimerJob.perform_in(VOTING_TIME.call, game, @@round)

      livp = game.living_players
      livp.each do |lp|
        send_voting(livp, lp[:full_name], lp[:user_id])
      end
    when VOTING_SUCCEEDED
      group_chat_id = game.group_id
      votee_chat_id = aux[0]
      votee_full_name = aux[1]
      votee_role = aux[2]

      log("voting succeeded, resulting in #{votee_full_name}'s death")
      send_to_player(votee_chat_id, 'MPOZ LO DIEKSEKUSI')
      send_to_player(group_chat_id, "Hasil bertulul berbuah eksekusi si #{votee_full_name}\nMPOZ MPOZ MPOZ\n\nTernyata dia itu #{votee_role}")
      list_voting(game)
      return if check_win(game)
      message_action(game, ROUND_START)
    when VOTING_FAILED
      group_chat_id = game.group_id
      log('voting failed')
      send_to_player(group_chat_id, 'Nulul tidak membuahkan mufakat')
      list_voting(game)
      message_action(game, ROUND_START)
    when ENLIGHTEN_SEER
      aux.each do |seen|
        seen_full_name = seen[0]
        seen_role = seen[1]
        seer_id = seen[2]

        log("sending #{seen_full_name}'s role #{seen_role} to seer: #{seer_id}")
        send_to_player(seer_id, "Dengan kekuatan maksiat, peran si #{seen_full_name} pun terlihat: #{seen_role}")
      end
    when DEAD_PROTECTORS
      aux.each do |dp|
        protector_name = dp[0]
        protector_id = dp[1]

        log("sending #{protector_name} failed protection notification")
        send_to_player(protector_id, "Jangan jualan ke sembarang orang! Lu jualan ke serigala, mati aja.")
        send_to_player(game.group_id, "Bego nih penjual jimat #{protector_name} malah jualan ke serigala :'))")
      end
    when ZOMBIE_REVIVED
      aux.each do |nc|
        necromancer = nc[0]
        necromancee = nc[1]

        log("sending necromancing messages to necromancer #{necromancer.full_name} and the raised #{necromancee.full_name}")
        send_to_player(necromancee.user_id, "Kamu telah dihidupkan kembali oleh seorang mujahid! Selamat datang kembali!")
        send_to_player(necromancer.user_id, "Kamu berhasil menghidupkan kembali #{necromancee.full_name}. Terima kasih, terima kasih, terima kasih. Kamu memang makhluk paling keren di muka bumi ini :*")

        end_message = " menghidupkan #{necromancee.full_name}, seorang #{game.get_role(necromancee.role)}. Ayo manfaatkan kesempatan ini sebaik mungkin!"
        case necromancer.role
        when Lycantulul::Game::NECROMANCER
          send_to_player(game.group_id, "#{necromancer.full_name} sang #{game.get_role(necromancer.role)} berhasil mengorbankan dirinya untuk" + end_message)
        when Lycantulul::Game::SUPER_NECROMANCER
          send_to_player(game.group_id, "Seorang #{game.get_role(necromancer.role)} yang tidak mau disebutkan namanya berhasil" + end_message)
        end
      end
    end
  end

  def self.send(message, text, reply: nil, html: nil)
    options = {
      chat_id: message.chat.id,
      text: text,
    }
    options.merge!({ reply_to_message_id: message.message_id }) if reply
    options.merge!({ parse_mode: 'HTML' }) if html
    log("sending to #{message.chat.id}: #{text}")
    #@@bot.api.send_message(options)
  end

  def self.send_to_player(chat_id, text, options = {})
    options.merge!({
      chat_id: chat_id,
      text: text,
    })
    log("sending to #{chat_id}: #{text}")
    #@@bot.api.send_message(options)
  end

  def self.send_kill_voting(game, chat_id)
    lw = game.living_werewolves
    single_w = lw.size == 1
    killables = game.killables.map{ |kl| kl[:full_name] }

    kill_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: killables, resize_keyboard: true, one_time_keyboard: true)

    send_to_player(chat_id, "Daftar TTS yang masih hidup: #{lw.map{ |w| w[:full_name] }.join(', ')}\n\np.s.: harus diskusi dulu. Jawaban semua TTS dikumpulin dan yang paling banyak dibunuh. Kalo ga ada suara yang mayoritas, ga ada yang terbunuh yaa") unless single_w
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

  def self.send_protector(living_players, protector_full_name, protector_chat_id)
    log("sending protector instruction to #{protector_full_name}")
    vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [protector_full_name], resize_keyboard: true, one_time_keyboard: true)
    send_to_player(protector_chat_id, 'Mau jual jimat ke siapa?', reply_markup: vote_keyboard)
  end

  def self.send_necromancer(dead_players, necromancer_chat_id)
    log("sending necromancer instruction to #{necromancer_chat_id}")
    options = [Lycantulul::Game::NECROMANCER_SKIP]
    options << dead_players.map{ |lv| lv[:full_name] }
    vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: options, resize_keyboard: true, one_time_keyboard: true)
    send_to_player(necromancer_chat_id, 'Mau menghidupkan siapa?', reply_markup: vote_keyboard)
  end

  def self.wrong_room(message)
    if in_private?(message)
      send(message, 'Di grup doang tjoy ini bisanya')
    elsif in_group?(message)
      send(message, 'PM mz mb! @lycantulul_bot', reply: true)
    end
  end

  def self.summon(game, who)
    to_call =
      case who
      when :all
        game.players
      when :alive
        game.living_players
      when :voting
        game.pending_voters
      end

    to_call_username = to_call.map(&:username).compact
    message =
      if to_call.empty?
        'Tidak ada'
      elsif who == :voting
        'Sudah dipanggil via PM ya'
      else
        'Hoy ' + to_call_username.map{ |tc| "@#{tc}" }.join(' ')
      end

    if who == :voting
      to_call.each do |tc|
        send_to_player(tc.user_id, 'Hai hai kamu belum voting udah ditungguin tuh sama yang lain')
      end
    end
    send_to_player(game.group_id, message)
  end

  def self.unregistered(message)
    send(message, 'Lau belom terdaftar cuy. PM gua @lycantulul_bot terus /start, baru balik sini dan lakukan lagi apa yang mau lu lakukan tadi', reply: true)
  end

  def self.bot_help
    'Lihat penjelasan permainan di https://github.com/tulul/lycantulul_bot/blob/master/README.md'
  end

  def self.remind(game, round, time, next_reminder, state)
    log('reminding voting')
    game.reload
    return unless next_reminder && round == game.round && !game.night? && !game.waiting? && !game.finished?
    log('continuing')
    send_to_player(game.group_id, "Waktu nulul tinggal #{time} detik.\n/panggil_yang_belom_voting atau liat /hasil_voting")
    Lycantulul::VotingTimerJob.perform_in(next_reminder, game, round, Lycantulul::VotingTimerJob.next_state(state), next_reminder)
  end

  def self.remind(game, round, time)
    log('reminding voting')
    game.reload
    return unless round == game.round && !game.night? && !game.waiting? && !game.finished?
    log('continuing')
    send_to_player(game.group_id, "Waktu nulul tinggal #{time} detik.\n/panggil_yang_belom_voting atau liat /hasil_voting")
  end

  def self.list_players(game)
    send_to_player(game.group_id, game.list_players, parse_mode: 'HTML')
  end

  def self.list_voting(game)
    send_to_player(game.group_id, game.list_voting, parse_mode: 'HTML')
  end

  def self.check_game(message)
    Lycantulul::Game.active_for_group(message.chat)
  end

  def self.check_player(message)
    Lycantulul::RegisteredPlayer.find_by(user_id: message.from.id)
  end

  def self.check_werewolf_in_game(message)
    log('checking werewolf votes')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.valid_action?(message.from.id, message.text, 'werewolf')
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_voting(message)
    log('checking voters')
    Lycantulul::Game.where(finished: false, waiting: false, night: false).each do |wwg|
      if wwg.valid_action?(message.from.id, message.text, 'player')
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_seer(message)
    log('checking seer')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.valid_action?(message.from.id, message.text, 'seer')
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_protector(message)
    log('checking protector')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.valid_action?(message.from.id, message.text, 'protector')
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_necromancer(message)
    log('checking necromancer')
    Lycantulul::Game.where(finished: false, waiting: false, night: true).each do |wwg|
      if wwg.valid_action?(message.from.id, message.text, 'necromancer') || wwg.valid_action?(message.from.id, message.text, 'super_necromancer')
        return wwg
      end
    end
    log('not found')
    nil
  end

  def self.check_round_finished(game, round, force = false)
    log("checking round finished #{round}")
    game.reload
    return unless round == game.round && game.night? && !game.waiting? && !game.finished?
    log('continuing')
    if force || game.round_finished?
      killed = game.kill_victim

      if (failed_protection = game.protect_players) && !failed_protection.empty?
        message_action(game, DEAD_PROTECTORS, failed_protection)
      end

      if (necromancee = game.raise_the_dead) && !necromancee.empty?
        message_action(game, ZOMBIE_REVIVED, necromancee)
      end

      if (seen = game.enlighten_seer) && !seen.empty?
        message_action(game, ENLIGHTEN_SEER, seen)
      end

      if killed
        message_action(game, WEREWOLF_KILL_SUCCEEDED, killed)
      else
        message_action(game, WEREWOLF_KILL_FAILED)
      end
    end
  end

  def self.check_voting_finished(game, round, force = false)
    log("checking voting finished: #{round}")
    game.reload
    return unless round == game.round && !game.night? && !game.waiting? && !game.finished?
    log('continuing')
    if force || game.votee.count == game.living_players.count
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
    if game.living_werewolves.count == 0
      log('wereworlves ded')
      send_to_player(game.group_id, 'Dan permainan pun berakhir karena seluruh TTS telah meninggal dunia. Mari doakan agar mereka tenang di sisi-Nya.')
      win = true
    elsif game.living_werewolves.count == game.killables.count || game.killables.count == 0
      log('villagers ded')
      send_to_player(game.group_id, 'Dan permainan pun berakhir karena TTS telah memenangkan permainan. Semoga mereka terkutuk seumur hidup.')
      win = true
    end

    if win
      game.finish
      list_players(game)

      ending = '<pre>'
      ending += ",          ____ _____  _____ \n"
      ending += "     /\\   |  _ \\_   _|/ ____|\n"
      ending += "    /  \\  | |_) || | | (___  \n"
      ending += "   / /\\ \\ |  _ &lt; | |  \\___ \\ \n"
      ending += "  / ____ \\| |_) || |_ ____) |\n"
      ending += " /_/    \\_\\____/_____|_____/ "
      ending += '</pre>'
      send_to_player(game.group_id, ending, parse_mode: 'HTML')
    end

    win
  end

  def self.in_group?(message)
    message.chat.type == 'group'
  end

  def self.in_private?(message)
    message.chat.type == 'private'
  end

  def self.log(message)
    puts "#{Time.now.utc} -- #{message.gsub("\n", ' ||| ')}"
  end
end
