load 'Rakefile'

updates = []
updates << 'latest updates:'
updates << '- Biduan dilemahin jadi cuma bisa 1x selamat dari serangan serigala. Soalnya lumayan banyak yang pake peran itu, imba'
updates << ''
updates << "- <a href='https://telegram.me/lycantulul_board'>Klik sini untuk join channel berisi update dari Lycantulul</a>"
updates << "- <a href='https://github.com/tulul/lycantulul_bot'>Klik sini kalo mau saran/lapor bug/kontribusi/dll (github)</a>"
updates << "- <a href='https://storebot.me/bot/lycantulul_bot'>Klik sini kalo mau ngasih rating/review (storebot)</a>"
updates << "- <a href='https://telegram.me/lycantulul'>Klik sini kalo grup kalian sepi dan pengen main bareng di grup publik</a>"
updates = updates.join("\n")

groups = Lycantulul::Game.all.map(&:group_id).uniq
puts "TARGET: #{groups.count}"

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates, parse_mode: 'HTML', disable_web_page_preview: true)
      success += 1
      sleep(0.05)
    rescue StandardError => e
      failure += 1
      puts e.message
      if e.message =~ /400/
        r = Lycantulul::Group.find_by(group_id: g)
        r && r.destroy
      end
    ensure
      if (success + failure) % 50 == 0
        puts "#{success}/#{failure}"
      end
    end
  end
end

puts "OK: #{success}"
puts "NO: #{failure}"
