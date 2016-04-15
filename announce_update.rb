load 'Rakefile'

updates = "latest updates:\n"
updates += "- Peran baru: Tamaki Shinichi\n"
updates += "- Muncul pas jumlah pemain udah 16\n"
updates += "- Tiap malem Tamaki bakal dikasih tau TTS pengen bunuh siapa. Terserah Tamaki aja infonya mau diapain\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
