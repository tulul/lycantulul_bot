load 'Rakefile'

#updates = "latest updates:\n"
updates = "Yuk join grup publik biar lebih rame: https://telegram.me/lycantulul"
groups = Lycantulul::RegisteredPlayer.all.map(&:user_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end

