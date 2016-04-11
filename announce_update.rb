load 'Rakefile'

updates = "latest updates:\n"
updates += "- role baru: dukun\n"
updates += "- dukun: tiap malem dikasih tau secara random role seseorang yang masih hidup (tidak dijamin besoknya dikasih tau orang yang berbeda). muncul saat jumlah pemain >11 dengan kemungkinan 75%\n"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
