load 'Rakefile'

updates = "latest updates:\n"
updates += "- Abis bunuh ga langsung voting, ada waktu diskusi. Bisa ganti juga pake /ganti_waktu_diskusi\n"
updates += "- Keyboard langsung ilang sekarang pas ngirim jawaban. Kalo ga ilang juga, masih ada /ilangin_keyboard\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
