load 'Rakefile'

updates = "latest updates:\n"
updates += "- perbaikin pas Pak Ogah voting dianggep belom voting\n"
updates += "- perbaikin pas ada Pak Ogah atau Pak Raden, ronde voting ga langsung selesai pas semua udah voting"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
