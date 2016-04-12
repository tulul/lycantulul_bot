load 'Rakefile'

updates = "latest updates:\n"
updates += "- /ganti_settingan_peran buat ngubah jumlah peran semau kita (cuma buat tts, intip, jimat, mujahid, ebola)\n"
updates += "- /batal_nyetting_peran jadi kalo mau jalanin yang /ganti_settingan_peran, itu ada step2-nya. kalo mau ulang dari awal, batalin dulu pake command ini\n"
updates += "- /apus_settingan_peran buat ngapus semua settingan peran yang udah dibikin"
updates += "- game ga bisa mulai kalo jumlah yang di-setting > jumlah pemain (misal setting 3 tts, 3 jimat tapi yang main cuma 5. plis)"
groups = Lycantulul::Game.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
