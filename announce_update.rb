load 'Rakefile'

updates = "latest updates:\n"
updates += "- KABAR GEMBIRA: Pak Raden, Pak Ogah, Dukun, Super Mujahid, dan Anak Presiden sekarang pasti ada (ga pake kemungkinan lagi)\n"
updates += "- Jadi kalo mau nyobain tapi pemainnya kurang, bisa diatur pake /ganti_settingan_peran ;)"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
