load 'Rakefile'

updates = "latest updates:\n"
updates += "- /ganti_waktu_voting dan /ganti_waktu_malam buat ngatur waktu\n"
updates += "- Formatnya /ganti_waktu_voting[spasi][angka dalam detik, minimal 10]"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
