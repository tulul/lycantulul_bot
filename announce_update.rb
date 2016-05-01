load 'Rakefile'

updates = "latest updates:\n"
updates += "- Pemain yang tidak voting selama 3x (tidak harus berturut2) akan dibunuh paksa\n"
updates += "\n"
updates += "- <a href='https://github.com/tulul/lycantulul_bot'>Klik sini kalo mau saran/lapor bug/dll (github)</a>\n"
updates += "- <a href='https://storebot.me/bot/lycantulul_bot'>Klik sini kalo mau ngasih rating/review (storebot)</a>\n"
updates += "- <a href='https://telegram.me/lycantulul'>Klik sini kalo grup kalian sepi dan pengen main bareng di grup publik</a>\n"
groups = Lycantulul::Game.all.map(&:group_id).uniq

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates, parse_mode: 'HTML', disable_web_page_preview: true)
      success += 1
      sleep(0.1)
    rescue StandardError => e
      failure += 1
      puts e.message
    end
  end
end

puts "TARGET: #{groups.count}"
puts "OK: #{success}"
puts "NO: #{failure}"
