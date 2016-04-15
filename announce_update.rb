load 'Rakefile'

updates = "latest updates:\n"
updates += "- Waktu Voting dan Waktu Malam sekarang bakal berlanjut ke game selanjutnya (jadi settingannya per grup, bukan per game lagi)\n"
updates += "- /statistik_grup (baru jumlah game sama yang menang tts atau warga kampung)\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
