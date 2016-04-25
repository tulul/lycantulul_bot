load 'Rakefile'

updates = "latest updates:\n"
updates += "- Settingan peran bakal tetep sama untuk game selanjutnya, ga perlu nyetting2 ulang lagi. Kalo mau ulang dari awal /apus_settingan_peran\n"
updates += "- Did I say that you can change role counts using /ganti_settingan_peran?\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
