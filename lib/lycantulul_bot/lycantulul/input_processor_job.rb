module Lycantulul
  class InputProcessorJob
    include SuckerPunch::Job

    attr_accessor :bot

    MINIMUM_PLAYER = -> { (res = $redis.get('lycantulul::minimum_player')) ? res.to_i : 5 }
    NIGHT_TIME = -> { (res = $redis.get('lycantulul::night_time')) ? res.to_i : 90 }
    # multiply of 8 please
    VOTING_TIME = -> { (res = $redis.get('lycantulul::voting_time')) ? res.to_i : 160 }
    DISCUSSION_TIME = -> { (res = $redis.get('lycantulul::discussion_time')) ? res.to_i : 120 }

    ALLOWED_DELAY = -> { (res = $redis.get('lycantulul::allowed_delay')) ? res.to_i : 20 }

    MAINTENANCE = -> { $redis.get('lycantulul::maintenance').to_i == 1 rescue nil }
    MAINTENANCE_PREVENT = -> { $redis.get('lycantulul::maintenance_prevent').to_i == 1 rescue nil }

    [
      'broadcast_role',
      'round_start',
      'werewolf_kill_broadcast',
      'werewolf_kill_succeeded',
      'werewolf_kill_failed',
      'discussion_start',
      'voting_start',
      'abstain',
      'voting_succeeded',
      'voting_failed',
      'enlighten_seer',
      'dead_protectors',
      'zombie_revived'
    ].each_with_index do |state, value|
      const_set(state.upcase, value)
    end

    def perform(message, bot)
      @bot = bot
      log("incoming message from #{message.from.first_name}: #{message.text}")

      if MAINTENANCE.call
        reply = in_group?(message)
        if !reply || message.text =~ /@lycantulul_(dev_)?bot/
          $redis.rpush('lycantulul::maintenance_info', message.chat.id)
          send(message, 'Lagi bermain bersama Ecchi-men Ryoman dan Nopak Jokowi', reply: reply)
        end
      elsif player_invalid?(message)
        reply = in_group?(message)
        if !reply || message.text =~ /@lycantulul_(dev_)?bot/
          send(message, 'Namanya jangan alay pake karakter-karakter aneh dong :( Ganti dulu!', reply: reply)
        end
      else
        if Time.now.to_i - message.date < ALLOWED_DELAY.call
          if new_member = message.new_chat_member
            unless Lycantulul::RegisteredPlayer.get(new_member.id) || new_member.username == 'lycantulul_bot'
              name = new_member.username ? "@#{new_member.username}" : new_member.first_name
              send(message, "Welcome #{name}. PM aku @lycantulul_bot terus /start yaa~", reply: true)
            end
          elsif left_member = message.left_chat_member
            if game = check_game(message)
              game.players.with_id(left_member.id).destroy rescue nil
            end
          end

          case message.text
          when /^\/start(@lycantulul_bot)?/
            if in_private?(message)
              if check_player(message)
                send(message, 'Udah kedaftar!')
              else
                Lycantulul::RegisteredPlayer.create_from_message(message.from)
                send(message, 'Terdaftar! Lood Guck and Fave hun! Kalo mau ikutan main, balik ke grup, terus pencet /ikutan')
              end
            else
              wrong_room(message)
            end
          when /^\/help(@lycantulul_bot)?/
            send(message, bot_help)
          when /^\/bikin_baru(@lycantulul_bot)?/
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
          when /^\/batalin(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  game.finish(stats: false)
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
          when /^\/ikutan(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if check_player(message)
                  if game.waiting?
                    user = message.from
                    unless game.duplicate_name?(user)
                      if game.add_player(user)
                        additional_text =
                          if game.players.count >= MINIMUM_PLAYER.call
                            res = "Udah bisa mulai btw, kalo mau /mulai_main yak. Atau enaknya nunggu makin rame lagi sih. Yok yang lain pada /ikutan\n\nPembagian peran:\n#{game.role_composition}\n"
                            res += "Tambah <b>#{game.next_new_role}</b> orang lagi ada peran peran penting tambahan.\n\n"
                            res += "#{game.list_settings}"
                            res
                          else
                            "#{MINIMUM_PLAYER.call - game.players.count} orang lagi buruan /ikutan"
                          end

                        send(message, "Welcome to the game, #{user.first_name}!\n\nUdah <b>#{game.players.count} orang</b> nich~ #{additional_text}", html: true)
                      else
                        send(message, 'Duh udah masuk lu', reply: true)
                      end
                    else
                      send(message, 'Namanya ga boleh sama kaya yang udah gabung, ganti nama!', reply: true)
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
          when /^\/gajadi(@lycantulul_bot)?/
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
          when /^\/ganti_settingan_peran(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  if !game.pending_custom_id
                    keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: game.role_setting_keyboard, resize_keyboard: true, one_time_keyboard: true, selective: true)
                    pending = send(message, 'Ubah jumlah peran siapa?', reply: true, keyboard: keyboard, async: false)
                    game.pending_reply(pending['result']['message_id']) rescue nil
                  else
                    send(message, 'Udah ada yang mulai nyetting tadi, selesaiin dulu atau /batal_nyetting_peran', reply: true)
                  end
                else
                  send(message, 'Udah mulai', reply: true)
                end
              else
                send(message, '/bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/batal_nyetting_peran(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  if game.pending_custom_id
                    game.cancel_pending_custom
                    send(message, 'Yosh. Udah boleh /ganti_settingan_peran lagi', reply: true)
                  else
                    send(message, 'Ga ada yang lagi nyetting, /ganti_settingan_peran dulu', reply: true)
                  end
                else
                  send(message, 'Udah mulai', reply: true)
                end
              else
                send(message, '/bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/apus_settingan_peran(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  if game.custom_roles
                    game.remove_custom_roles
                    send(message, 'Ok ;)', reply: true)
                  else
                    send(message, 'Belom ada yang nyetting2 peran, /ganti_settingan_peran dulu', reply: true)
                  end
                else
                  send(message, 'Udah mulai', reply: true)
                end
              else
                send(message, '/bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/ganti_settingan_voting(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  game.toggle_voting_scheme
                  send(message, "Sistem voting berubah jadi #{game.voting_scheme}", reply: true)
                else
                  send(message, 'Udah mulai', reply: true)
                end
              else
                send(message, '/bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/mulai_main(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                if game.waiting?
                  if !MAINTENANCE_PREVENT.call
                    if game.players.count >= MINIMUM_PLAYER.call
                      if game.role_valid?
                        game.start
                        message_action(game, BROADCAST_ROLE)
                        message_action(game, ROUND_START)
                      else
                        send(message, 'Pembagian peran yang dikasih ga valid, /apus_settingan_peran atau /ganti_settingan_peran!', reply: true)
                      end
                    else
                      send(message, "Belom #{MINIMUM_PLAYER.call} orang! Tidak bisa~ Yang lain mending /ikutan dulu biar bisa mulai", reply: true)
                    end
                  else
                    $redis.rpush('lycantulul::maintenance_info', message.chat.id)
                    send(message, 'Jangan /mulai_main dulu ya, mau main tenis bentar', reply: true)
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
          when /^\/siapa_aja(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                list_players(game)
              else
                send(message, 'Ga ada, orang ga ada yang maen. /bikin_baru gih', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/hasil_voting(@lycantulul_bot)?/
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
          when /^\/panggil_semua(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                summon(game, :all)
              else
                send(message, 'Ga ada yang lagi main, /bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/panggil_yang_idup(@lycantulul_bot)?/
            if in_group?(message)
              if game = check_game(message)
                summon(game, :alive)
              else
                send(message, 'Ga ada yang lagi main, /bikin_baru dulu', reply: true)
              end
            else
              wrong_room(message)
            end
          when /^\/panggil_yang_belom_voting(@lycantulul_bot)?/
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
          when /^\/ganti_settingan_waktu(@lycantulul_bot)?/
            if in_group?(message)
              if group = Lycantulul::Group.get(message)
                if !group.pending_time_id
                  keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: group.time_setting_keyboard, resize_keyboard: true, one_time_keyboard: true, selective: true)
                  pending = send(message, 'Ubah waktu apa?', reply: true, keyboard: keyboard, async: false)
                  group.pending_reply(pending['result']['message_id']) rescue nil
                else
                  send(message, 'Udah ada yang mulai nyetting tadi, selesaiin dulu atau /batal_nyetting_waktu', reply: true)
                end
              end
            else
              wrong_room(message)
            end
          when /^\/batal_nyetting_waktu(@lycantulul_bot)?/
            if in_group?(message)
              if group = Lycantulul::Group.get(message)
                if group.pending_time_id
                  group.cancel_pending_time
                  send(message, 'Yosh. Udah boleh /ganti_settingan_waktu lagi', reply: true)
                else
                  send(message, 'Ga ada yang lagi nyetting, /ganti_settingan_waktu dulu', reply: true)
                end
              end
            else
              wrong_room(message)
            end
          when /^\/ilangin_keyboard(@lycantulul_bot)?/
            keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true, selective: true)
            send(message, 'OK', reply: in_group?(message), keyboard: keyboard)
          when /^\/statistik_grup(@lycantulul_bot)?/
            if in_group?(message)
              send_to_player(message.chat.id, Lycantulul::Group.get(message).statistics, parse_mode: 'HTML')
            else
              wrong_room(message)
            end
          when /^\/statistik(@lycantulul_bot)?/
            if in_private?(message)
              if check_player(message)
                send_to_player(message.chat.id, Lycantulul::RegisteredPlayer.get(message.from.id).statistics, parse_mode: 'HTML')
              else
                send(message, 'Maaf belum kedaftar, /start dulu yak')
              end
            else
              wrong_room(message)
            end
          when /^\/stats/
            return unless message.from.username == 'araishikeiwai'
            (stat = Lycantulul::Statistics.get_stats(message.text)) && send(message, stat, html: true)
          else
            if in_private?(message)
              if game = check_werewolf_in_game(message)
                log('werewolf confirmed')
                case game.add_victim(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  message_action(game, WEREWOLF_KILL_BROADCAST, [message.from.id, message.text])
                when Lycantulul::Game::RESPONSE_INVALID
                  send_kill_voting(game, message.chat.id)
                end

                check_round_finished(game, game.round)
              elsif game = check_voting(message)
                log('voter confirmed')
                case game.add_votee(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                  send(message, 'Seeep', keyboard: keyboard)
                  voter = game.public_vote? ? "<b>#{message.from.first_name}</b>" : '<i>Seseorang</i>'
                  send_to_player(game.group_id, "#{voter} <i>udah nge-vote:</i> <b>#{message.text}</b>", parse_mode: 'HTML')
                when Lycantulul::Game::RESPONSE_INVALID
                  full_name = Lycantulul::Player.get_full_name(message.from)
                  send_voting(game.living_players, full_name, message.chat.id)
                end

                check_voting_finished(game, game.round)
              elsif game = check_seer(message)
                log('seer confirmed')
                case game.add_seen(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                  send(message, 'Seeep. Tunggu ronde berakhir yak, kalo lu atau yang mau lu liat mati, ya jadi ga ngasih tau~', keyboard: keyboard)
                when Lycantulul::Game::RESPONSE_INVALID
                  full_name = Lycantulul::Player.get_full_name(message.from)
                  send_seer(game.living_players, full_name, message.chat.id)
                end

                check_round_finished(game,game.round)
              elsif game = check_protector(message)
                log('protector confirmed')
                case game.add_protectee(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                  send(message, 'Seeep', keyboard: keyboard)
                when Lycantulul::Game::RESPONSE_INVALID
                  full_name = Lycantulul::Player.get_full_name(message.from)
                  send_protector(game.living_players, full_name, message.chat.id)
                end

                check_round_finished(game, game.round)
              elsif game = check_necromancer(message)
                log('necromancer confirmed')
                case game.add_necromancee(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                  send(message, 'Seeep. Kamu sungguh berjasa :\') Tapi kalo kamu dibunuh serigala, gajadi deh :\'(', keyboard: keyboard)
                when Lycantulul::Game::RESPONSE_SKIP
                  send(message, 'Okay, sungguh bijaksana')
                when Lycantulul::Game::RESPONSE_INVALID
                  send_necromancer(game.dead_players, message.chat.id)
                end

                check_round_finished(game, game.round)
              elsif game = check_homeless(message)
                log('homeless confirmed')
                case game.add_homeless_host(message.from.id, message.text)
                when Lycantulul::Game::RESPONSE_OK
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
                  send(message, 'Selamat datang! Anggap saja rumah sendiri~', keyboard: keyboard)
                when Lycantulul::Game::RESPONSE_INVALID
                  full_name = Lycantulul::Player.get_full_name(message.from)
                  send_homeless(game.living_players, full_name, message.chat.id)
                end

                check_round_finished(game, game.round)
              else
                send(message, 'WUT?')
              end
            else
              if (game = check_game(message)) && (game.pending_custom_id == message.reply_to_message.message_id rescue false)
                if message.text =~ /^\d+$/ && game.pending_custom_role
                  res = game.set_custom_role(message.text.to_i)
                  return unless res
                  keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true, selective: true)
                  send(message, "Sip. Jumlah #{res[0]} ntar jadi #{res[1]}", reply: true, keyboard: keyboard)
                elsif (role = game.check_custom_role(message.text))
                  force = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)
                  pending = send(message, "Mau berapa #{game.get_role(role)}?", reply: true, keyboard: force, async: false)
                  game.pending_reply(pending['result']['message_id']) rescue nil
                else
                  send(message, 'WUT?', reply: true)
                end
              elsif (group = Lycantulul::Group.get(message)) && (group.pending_time_id == message.reply_to_message.message_id rescue false)
                if message.text =~ /^\d+$/ && group.pending_time
                  time = message.text.to_i
                  if time >= 10 && time <= 300
                    res = group.set_custom_time(time)
                    keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true, selective: true)
                    send(message, "Sip, waktu #{res[0]} jadi #{res[1]} detik!", reply: true, keyboard: keyboard)
                  else
                    group.cancel_pending_time
                    keyboard = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true, selective: true)
                    send(message, "Sejak kapan 10 <= #{time.to_i} <= 300? Ulang /ganti_settingan_waktu lagi", reply: true, keyboard: keyboard)
                  end
                elsif group.check_time_setting(message.text)
                  force = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)
                  pending = send(message, "Mau berapa detik? (10-300 detik)", reply: true, keyboard: force, async: false)
                  group.pending_reply(pending['result']['message_id']) rescue nil
                else
                  send(message, 'WUT?', reply: true)
                end
              end
            end
          end
        else
          log('stale message. purged')
        end
      end
    rescue Faraday::TimeoutError => e
      puts Time.now.utc
      puts 'TIMEOUT'
      sleep(1)
      retry
    rescue StandardError => e
      err = e.message + "\n"
      err += e.backtrace.select{ |err| err =~ /tulul/ }.join(', ') + "\n"
      err += Time.now.utc.to_s
      puts err
      $redis.set('lycantulul::maintenance_prevent', 1)
      $redis.set('lycantulul::maintenance', 1)
      rg = Lycantulul::Game.running
      send_to_player(Lycantulul::RegisteredPlayer.find_by(username: 'araishikeiwai').user_id, "EXCEPTION! CHECK SERVER! #{rg.count} GAMES STOPPED\n\n#{err}")
      rg.each do |rg|
        rg.finish(stats: false)
        send_to_player(rg.group_id, 'Maaf ada error sesuatu, permainan terpaksa dihentikan dan main tenis. Maap yak')
      end
      retry
    end

    def message_action(game, action, aux = nil)
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

        send_to_player(group_chat_id, "Malam pun tiba, para penduduk desa pun terlelap dalam gelap.\nNamun #{game.living_werewolves.count + game.living_super_werewolves.count} serigala culas diam-diam mengintai mereka yang tertidur pulas.\n\np.s.: Buruan action via PM, cuma ada waktu <b>#{game.night_time} detik</b>! Kecuali warga kampung, diam aja menunggu kematian ya", parse_mode: 'HTML')
        log('enqueuing night job')
        Lycantulul::NightTimerJob.perform_in(game.night_time, game, game.round, self)

        (game.living_werewolves + game.living_super_werewolves).each do |ww|
          send_kill_voting(game, ww[:user_id])
        end

        lp = game.living_players
        game.living_seers.each do |se|
          send_seer(lp, se[:full_name], se[:user_id])
        end

        game.living_faux_seers.each do |se|
          send_faux_seer(game, se)
        end

        game.living_protectors.each do |se|
          send_protector(lp, se[:full_name], se[:user_id])
        end

        game.living_homelesses.each do |se|
          send_homeless(lp, se[:full_name], se[:user_id])
        end

        dp = game.dead_players
        game.living_necromancers.each do |se|
          send_necromancer(dp, se[:user_id])
        end

        game.living_super_necromancers.each do |se|
          !game.super_necromancer_done[se[:user_id].to_s] && send_necromancer(dp, se[:user_id])
        end
      when WEREWOLF_KILL_BROADCAST
        lw = (game.living_werewolves + game.living_super_werewolves + game.living_spies)
        killer = game.players.with_id(aux[0])
        victim_name = aux[1]

        lw.each do |ww|
          log("broadcasting killing from #{killer.full_name}")
          brd = "#{victim_name} pengen dibunuh"
          [Lycantulul::Game::WEREWOLF, Lycantulul::Game::SUPER_WEREWOLF].include?(ww.role) && brd += " oleh #{killer.full_name}"
          send_to_player(ww.user_id, brd) unless ww.role == Lycantulul::Game::SPY && killer.role == Lycantulul::Game::SUPER_WEREWOLF
        end
      when WEREWOLF_KILL_SUCCEEDED
        group_chat_id = game.group_id
        victim_chat_id = aux[0]
        victim_full_name = aux[1]
        victim_role = aux[2]
        dead_werewolf = aux[3]
        dead_homeless = aux[4]

        log("#{victim_full_name} is killed by werewolves")
        send_to_player(victim_chat_id, 'MPOZ LO MATEK')
        send_to_player(group_chat_id, "GILS GILS GILS\nserigala berhasil memakan si #{victim_full_name}\nMPOZ MPOZ MPOZ\n\nTernyata dia itu #{victim_role}")

        if dead_werewolf
          send_to_player(dead_werewolf.user_id, "MPOZ. Sial kan bunuh #{game.get_role(Lycantulul::Game::SILVER_BULLET)}, lu ikutan terjangkit. Mati deh")
          send_to_player(group_chat_id, "#{victim_full_name} yang ternyata mengidap ebola ikut menjangkiti seekor serigala #{dead_werewolf.full_name} yang pada akhirnya meninggal dunia. Mari berantas ebola dari muka bumi ini secepatnya!")
        end

        unless dead_homeless.empty?
          dead_homeless.each do |dh|
            send_to_player(dh.user_id, 'MPOZ salah kamar woy nebeng yang bener ya besok-besok!')
            send_to_player(group_chat_id, "#{dh.full_name} si #{game.get_role(dh.role)} salah kamar tadi malem, nebeng di tempat yang salah pffft. Mati deh.")
          end
        end

        return if check_win(game)
        message_action(game, DISCUSSION_START)
      when WEREWOLF_KILL_FAILED
        group_chat_id = game.group_id
        log('no victim')
        send_to_player(group_chat_id, 'PFFFTTT CUPU BANGET SERIGALA PADA, ga ada yang mati')
        return if check_win(game)
        message_action(game, DISCUSSION_START)
      when DISCUSSION_START
        group_chat_id = game.group_id
        send_to_player(group_chat_id, "Silakan bertulul dan bermufakat, waktunya cuma <b>#{game.discussion_time} detik</b>", parse_mode: 'HTML')
        log('enqueuing discussion job')
        Lycantulul::DiscussionTimerJob.perform_in(game.discussion_time, game, game.round, self)
      when VOTING_START
        group_chat_id = game.group_id
        send_to_player(group_chat_id, "Silakan voting siapa yang mau dieksekusi.\n\np.s.: semua wajib voting, waktunya cuma <b>#{game.voting_time} detik</b>. kalo ga ada suara mayoritas, ga ada yang mati", parse_mode: 'HTML')
        log('enqueuing voting job')
        Lycantulul::VotingTimerJob.perform_in(game.voting_time / 2, game, game.round, Lycantulul::VotingTimerJob::START, game.voting_time / 2, self)

        livp = game.living_players
        livp.each do |lp|
          send_voting(livp, lp[:full_name], lp[:user_id])
        end
      when ABSTAIN
        group_chat_id = game.group_id
        abstains = aux

        abstains.each do |abs|
          send_to_player(abs.user_id, "#{Lycantulul::Player::ABSTAIN_LIMIT}x tidak voting, terpaksa harus dibunuh")
        end

        send_to_player(group_chat_id, "Pemain yang tidak voting #{Lycantulul::Player::ABSTAIN_LIMIT}x dan dibunuh paksa:\n#{abstains.map{ |abs| "- <b>#{abs.full_name}</b> - <i>#{game.get_role(abs.role)}</i>" }.join("\n")}", parse_mode: 'HTML')
      when VOTING_SUCCEEDED
        group_chat_id = game.group_id
        votee = aux

        amnestied = votee.role == Lycantulul::Game::AMNESTY && votee.alive

        if amnestied
          log("voting amnestied, resulting in #{votee.full_name}'s survival")
          send_to_player(votee.user_id, 'CIYEEE ANAK PRESIDEN SELAMET YEE GA JADI MATI')
          send_to_player(group_chat_id, "Hasil bertulul berbuah eksekusi si #{votee.full_name}\nNamun ternyata dia itu #{game.get_role(votee.role)}, selamatlah dia dari eksekusi kali ini")
        else
          log("voting succeeded, resulting in #{votee.full_name}'s death")
          send_to_player(votee.user_id, 'MPOZ LO DIEKSEKUSI')
          send_to_player(group_chat_id, "Hasil bertulul berbuah eksekusi si #{votee.full_name}\nMPOZ MPOZ MPOZ\n\nTernyata dia itu #{game.get_role(votee.role)}")
        end
        return if check_win(game)
        message_action(game, ROUND_START)
      when VOTING_FAILED
        group_chat_id = game.group_id
        log('voting failed')
        send_to_player(group_chat_id, 'Nulul tidak membuahkan mufakat')
        return if check_win(game)
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
          send_to_player(game.group_id, "Bego nih #{game.get_role(Lycantulul::Game::PROTECTOR)} si #{protector_name} malah jualan ke serigala :'))")
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

    def send(message, text, reply: nil, html: nil, keyboard: nil, async: true)
      options = {
        chat_id: message.chat.id,
        text: text[0...4000],
      }
      options.merge!({ reply_to_message_id: message.message_id }) if reply
      options.merge!({ parse_mode: 'HTML' }) if html
      options.merge!({ reply_markup: keyboard }) if keyboard
      if async
        Lycantulul::MessageSendingJob.perform_async(@bot, options)
      else
        retry_count = 0
        begin
          @bot.api.send_message(options)
        rescue Faraday::TimeoutError => e
          puts Time.now.utc
          puts 'TIMEOUT'
          sleep(2)
          retry
        rescue Telegram::Bot::Exceptions::ResponseError => e
          puts Time.now.utc
          puts e.message
          puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
          puts "retrying: #{retry_count}"

          if e.message =~ /429/
            sleep(3)
          elsif e.message =~ /403/
            Lycantulul::RegisteredPlayer.find_by(user_id: message.chat.id).update_attribute(:blocked, true) rescue nil
          end
          retry if e.message !~ /[400|403|409]/ && (retry_count += 1) < 20
        end
      end
    end

    def send_to_player(chat_id, text, options = {})
      options.merge!({
        chat_id: chat_id,
        text: text[0...4000],
      })
      Lycantulul::MessageSendingJob.perform_async(@bot, options)
    end

    def send_kill_voting(game, chat_id)
      lw = game.living_werewolves + game.living_super_werewolves
      single_w = lw.size == 1
      killables = game.killables.map{ |kl| kl[:full_name] }

      kill_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: killables, resize_keyboard: true, one_time_keyboard: true)

      send_to_player(chat_id, "Daftar serigala yang masih hidup: #{lw.map{ |w| w[:full_name] }.join(', ')}\n\np.s.: harus diskusi dulu. Jawaban semua serigala dikumpulin dan yang paling banyak dibunuh. Kalo ga ada suara yang mayoritas, ga ada yang terbunuh yaa") unless single_w
      send_to_player(chat_id, 'Mau bunuh siapa?', reply_markup: kill_keyboard)
    end

    def send_voting(living_players, player_full_name, player_chat_id)
      log("sending voting to #{player_full_name}")
      vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [player_full_name], resize_keyboard: true, one_time_keyboard: true)
      send_to_player(player_chat_id, 'Ayo voting eksekusi siapa nih~', reply_markup: vote_keyboard)
    end

    def send_seer(living_players, seer_full_name, seer_chat_id)
      log("sending seer instruction to #{seer_full_name}")
      vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [seer_full_name], resize_keyboard: true, one_time_keyboard: true)
      send_to_player(seer_chat_id, 'Mau ngintip perannya siapa kak? :3', reply_markup: vote_keyboard)
    end

    def send_faux_seer(game, seer)
      log("sending seer instruction to #{seer.full_name}")
      chosen = seer
      while chosen.user_id == seer.user_id
        chosen = game.living_players.sample
      end

      chosen_role = chosen.role == Lycantulul::Game::SUPER_WEREWOLF ? game.get_role(game.living_players.without_role([Lycantulul::Game::FAUX_SEER]).sample.role) : game.get_role(chosen.role)
      send_to_player(seer.user_id, "Hum bala hum bala hum naga cinta membuka mata acha septriasa: peran #{chosen.full_name} adalah #{chosen_role}")
    end

    def send_protector(living_players, protector_full_name, protector_chat_id)
      log("sending protector instruction to #{protector_full_name}")
      vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [protector_full_name], resize_keyboard: true, one_time_keyboard: true)
      send_to_player(protector_chat_id, 'Mau jual jimat ke siapa?', reply_markup: vote_keyboard)
    end

    def send_necromancer(dead_players, necromancer_chat_id)
      log("sending necromancer instruction to #{necromancer_chat_id}")
      options = [Lycantulul::Game::NECROMANCER_SKIP]
      options << dead_players.map{ |lv| lv[:full_name] }
      vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: options, resize_keyboard: true, one_time_keyboard: true)
      send_to_player(necromancer_chat_id, 'Mau menghidupkan siapa?', reply_markup: vote_keyboard)
    end

    def send_homeless(living_players, homeless_full_name, homeless_chat_id)
      log("sending homeless instruction to #{homeless_full_name}")
      vote_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: living_players.map{ |lv| lv[:full_name] } - [homeless_full_name], resize_keyboard: true, one_time_keyboard: true)
      send_to_player(homeless_chat_id, 'Mau nebeng di rumah siapa?', reply_markup: vote_keyboard)
    end

    def wrong_room(message)
      if in_private?(message)
        send(message, 'Di grup doang tjoy ini bisanya')
      elsif in_group?(message)
        send(message, 'PM mz mb! @lycantulul_bot', reply: true)
      end
    end

    def summon(game, who)
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

    def unregistered(message)
      send(message, 'Belom terdaftar (atau lu nge-block gua) cuy. PM gua @lycantulul_bot terus /start (jangan lupa unblock dulu), baru balik sini dan lakukan lagi apa yang mau lu lakukan tadi', reply: true)
    end

    def bot_help
      'Lihat penjelasan permainan di https://github.com/tulul/lycantulul_bot/blob/master/README.md'
    end

    def remind(game, round, time, next_reminder, state)
      log('reminding voting')
      game.reload
      return unless next_reminder && round == game.round && !game.night? && !game.waiting? && !game.finished?
      log('continuing')
      send_to_player(game.group_id, "Waktu voting tinggal #{time} detik.\n/panggil_yang_belom_voting atau liat /hasil_voting")
      Lycantulul::VotingTimerJob.perform_in(next_reminder, game, round, Lycantulul::VotingTimerJob.next_state(state), next_reminder, self)
    end

    def list_players(game)
      send_to_player(game.group_id, game.list_players, parse_mode: 'HTML')
    end

    def list_voting(game)
      send_to_player(game.group_id, game.list_voting, parse_mode: 'HTML')
    end

    def check_game(message)
      Lycantulul::Game.active_for_group(message.chat)
    end

    def check_player(message)
      rp = Lycantulul::RegisteredPlayer.get_and_update(message.from)
      rp && !rp.blocked?
    end

    def check_werewolf_in_game(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: true, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'werewolf') || wwg.valid_action?(message.from.id, message.text, 'super_werewolf')
          return wwg
        end
      end
      nil
    end

    def check_voting(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: false, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'player')
          return wwg
        end
      end
      nil
    end

    def check_seer(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: true, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'seer')
          return wwg
        end
      end
      nil
    end

    def check_protector(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: true, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'protector')
          return wwg
        end
      end
      nil
    end

    def check_necromancer(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: true, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'necromancer') || wwg.valid_action?(message.from.id, message.text, 'super_necromancer')
          return wwg
        end
      end
      nil
    end

    def check_homeless(message)
      Lycantulul::Game.where(finished: false, waiting: false, night: true, discussion: false).each do |wwg|
        if wwg.valid_action?(message.from.id, message.text, 'homeless')
          return wwg
        end
      end
      nil
    end

    def check_round_finished(game, round, force = false)
      log("checking round finished #{round}")
      game.reload
      return unless round == game.round && game.night? && !game.waiting? && !game.discussion? && !game.finished?
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

    def end_discussion_and_start_voting(game, round, force = false)
      log("starting voting round from discussion: #{round}")
      game.reload
      return unless round == game.round && !game.night? && !game.waiting? && game.discussion? && !game.finished?
      game.end_discussion
      message_action(game, VOTING_START)
    end

    def check_voting_finished(game, round, force = false)
      log("checking voting finished: #{round}")
      game.reload
      return unless round == game.round && !game.night? && !game.waiting? && !game.discussion? && !game.finished?
      log('continuing')
      if force || game.check_voting_finished
        list_voting(game)
        killed = game.kill_votee
        abstains = game.kill_abstain

        message_action(game, ABSTAIN, abstains) unless abstains.empty?

        if killed
          message_action(game, VOTING_SUCCEEDED, killed)
        else
          message_action(game, VOTING_FAILED)
        end
      end
    end

    def check_win(game)
      log('checking win condition')
      game.reload
      win = false
      if game.living_werewolves.count + game.living_super_werewolves.count == 0
        log('werewolves ded')
        send_to_player(game.group_id, 'Dan permainan pun berakhir karena seluruh serigala telah meninggal dunia. Mari doakan agar mereka tenang di sisi-Nya.')
        win = true
      elsif game.living_werewolves.count + game.living_super_werewolves.count == game.killables.count || game.killables.count == 0
        log('villagers ded')
        send_to_player(game.group_id, 'Dan permainan pun berakhir karena serigala telah memenangkan permainan. Semoga mereka terkutuk seumur hidup.')
        win = true
      end

      if win
        game.finish
        list_players(game)

        ending = '<pre>'
        ending += ".    /\\    \n"
        ending += "    /  \\   \n"
        ending += "   / /\\ \\  \n"
        ending += "  / ____ \\ \n"
        ending += " /_/__  \\_\\\n"
        ending += " |  _ \\    \n"
        ending += " | |_) |   \n"
        ending += " |  _ &lt;    \n"
        ending += " | |_) |   \n"
        ending += " |____/    \n"
        ending += " |_   _|   \n"
        ending += "   | |     \n"
        ending += "   | |     \n"
        ending += "  _| |_    \n"
        ending += " |_____|   \n"
        ending += "  / ____|  \n"
        ending += " | (___    \n"
        ending += "  \\___ \\   \n"
        ending += "  ____) |  \n"
        ending += " |_____/   "
        ending += '</pre>'
        send_to_player(game.group_id, ending, parse_mode: 'HTML')
      end

      win
    end

    def in_group?(message)
      ['group', 'supergroup'].include?(message.chat.type)
    end

    def in_private?(message)
      message.chat.type == 'private'
    end

    def player_invalid?(message)
      player = message.from

      string = "#{player.first_name}#{player.last_name}".downcase
      res = string =~ /[`\/\\:*_\[\](){}]/

      reserved_words = [Lycantulul::Game::NECROMANCER_SKIP, Lycantulul::Game::USELESS_VILLAGER_SKIP]
      res ||= reserved_words.include?(Lycantulul::Player.get_full_name(player))

      res
    end

    def log(message)
      LycantululBot.log(message)
    end
  end
end
