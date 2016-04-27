load 'Rakefile'

updates = "latest updates:\n"
updates += "- <b>Fitur Baru</b>: /ganti_settingan_voting --> ngubah sistem voting untuk grup, apakah publik (semua tau siapa voting siapa) atau rahasia (cuma tau siapa yang di-voting)\n"
updates += "- /ganti_settingan_waktu sekarang lebih kece (dibikin keyboard custom kaya /ganti_settingan_peran)\n"
updates += "- Otomatis main tenis kalo ada error yang aneh (harusnya sih mudah2an ga ada)"
updates += "\n"
updates += "- <a href='https://github.com/tulul/lycantulul_bot'>Klik sini kalo mau saran/lapor bug/dll (github)</a>\n"
updates += "- <a href='https://storebot.me/bot/lycantulul_bot'>Klik sini kalo mau ngasing rating/review (storebot)</a>\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 dan darurat kontak @araishikeiwai (time zone WIB-6 --> kalo di Jakarta jam 12 siang, dia masih jam 6 pagi jadi maklum kalo slow response) yak, kalo engga ke github aja bikin issue (lagi minggu2 ujian, doakan dia ya)"
groups = Lycantulul::Game.all.map(&:group_id).uniq

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates, parse_mode: 'HTML')
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
