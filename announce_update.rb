load 'Rakefile'

updates = "latest updates:\n"
updates += "- Peran baru: Gelandangan\n"
updates += "- Gelandangan: Muncul saat jumlah pemain 16\n"
updates += "- Gelandangan: Nebeng ke rumah orang lain tiap malem, jadi imun terhadap serangan TTS. Kalo yang dikunjungi dibunuh TTS atau adalah TTS, ikutan mati."
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
