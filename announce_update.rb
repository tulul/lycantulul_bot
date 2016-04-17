load 'Rakefile'

updates = "latest updates:\n"
updates += "- Setiap ada yang voting, dikasih tau siapa yang di-voting (tapi ga dikasih tau siapa yang voting)\n"
updates += "- Pas waktu voting berakhir, dikasih tau hasil voting terakhir\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
