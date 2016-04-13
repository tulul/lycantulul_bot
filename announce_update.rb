load 'Rakefile'

updates = "latest updates:\n"
updates += "- ascii art 'ABIS' di akhir permainan dibikin ke bawah biar lebih kebaca dan bisa dibaca di hp layar sempit\n"
updates += "- tiap ada yang voting dikasih tau ke grup 'seseorang udah voting' tapi tetep rahasia siapa voting siapa"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
