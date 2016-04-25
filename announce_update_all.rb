load 'Rakefile'

#updates = "latest updates:\n"
updates = "Hai semua, alhamdulillah yah sampe saat pesan ini dibuat ada:\n"
updates += "- 236 pemain yang terdaftar\n"
updates += "- 245 game yang udah dimainin --> ini aneh sih kok jumlahnya hampir sama kek jumlah pemain\n"
updates += "- 29 group yang masukin\n"
updates += "\n"
updates += "Mau ngasih tau biar pada join grup publik biar lebih rame: https://telegram.me/lycantulul\n"
updates += "\n"
updates += "Oiya, kalo ada yang bisa koding2 Ruby bolehlah ikut moles game-nya, main-main ke https://github.com/tulul/lycantulul_bot soalnya @araishikeiwai sebulan ke depan mau ujian, jadi mungkin kalo ada yang pengen improvement apa gitu ga bisa langsung dikabulkan"
groups = Lycantulul::RegisteredPlayer.all.map(&:user_id).uniq
count = 0
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates)
      puts (count += 1)
      sleep(0.1)
    rescue StandardError => e
      puts e.message
    end
  end
end

