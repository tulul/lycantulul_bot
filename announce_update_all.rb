load 'Rakefile'

updates = []
updates << 'Halo~'
updates << "Lama tak berjumpa, I've been busy with dissertation~"
updates << 'Ditinggal berbulan-bulan tanpa pengembangan apapun, tak disangka masih banyak pemain aktif, bahkan bertambah!'
updates << "Terhitung sejak 17 Mei 2016, ada #{Lycantulul::Group.where(:created_at.gte => DateTime.new(2016, 5, 17)).count} grup baru, #{Lycantulul::RegisteredPlayer.where(:created_at.gte => DateTime.new(2016, 5, 17)).count} pemain baru, dan #{Lycantulul::Game.where(:created_at.gte => DateTime.new(2016, 5, 17)).count} permainan yang dilakukan!"
updates << ''
updates << 'Coming soon: Logo Baru Lycantulul! (...setelah ditinggal hampir tiga bulan)'
updates << ''
updates << "<b>Meanwhile, join channel berisi update dari Lycantulul di </b><a href='https://telegram.me/lycantulul_board'>sini</a><b> ya~ Biar ndak kasih info via PM/group lagi</b>"
updates << ''
updates << "- <a href='https://telegram.me/lycantulul_board'>Klik sini untuk join channel berisi update dari Lycantulul</a>"
updates << "- <a href='https://github.com/tulul/lycantulul_bot'>Klik sini kalo mau saran/lapor bug/kontribusi/dll (github)</a>"
updates << "- <a href='https://storebot.me/bot/lycantulul_bot'>Klik sini kalo mau ngasih rating/review (storebot)</a>"
updates << "- <a href='https://telegram.me/lycantulul'>Klik sini kalo grup kalian sepi dan pengen main bareng di grup publik</a>"
updates = updates.join("\n")
puts updates.length

groups = Lycantulul::RegisteredPlayer.all.map(&:user_id).uniq
puts "TARGET: #{groups.count}"

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates, parse_mode: 'HTML', disable_web_page_preview: true, disable_notification: true)
      success += 1
      sleep(0.05)
    rescue StandardError => e
      if e.message =~ /403/
        Lycantulul::RegisteredPlayer.find_by(user_id: g).update_attribute(:blocked, true) rescue nil
      end
      failure += 1
      puts e.message
    ensure
      if (success + failure) % 50 == 0
        puts "#{success}/#{failure}"
      end
    end
  end
end

puts "OK: #{success}"
puts "NO: #{failure}"
