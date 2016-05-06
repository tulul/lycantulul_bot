load 'Rakefile'

updates = "latest updates:\n"
updates += "- beberapa ada yang bingung dong, /mulai_main dulu baru semua pada /rede, jangan /rede sebelom /mulai_main. /rede yang diitung cuma yang sejak /mulai_main dipanggil\n"
updates += "- bahasa gampang nih: /mulai_main itu ngasih aba2 30 detik lagi game dimulai, tapi dalam 30 detik itu semua pemain harus stand-by dan ngasih tanda /rede. kalo ada pemain yang belom /rede, game ga bisa dimulai dan harus ulang ngasih aba-aba /mulai_main lagi dan semua /rede ulang lagi\n"
updates += "- 1 hari ini testing dulu. kalo fiturnya kurang guna, besok diilangin deh. soalnya sering game dimulai padahal pemain2 lagi pada afk\n"
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
