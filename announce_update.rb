load 'Rakefile'

updates = "latest updates:\n"
updates += "- Sekarang bisa lebih dari 1 Anak Presiden/Super Mujahid\n"
updates += "- Silakan dicoba main pake >1 peran di atas. Ganti pake /ganti_settingan_peran sebelom mulai main\n"
updates += "- Harusnya masing-masing Anak Presiden/Super Mujahid udah bisa action sendiri2 (kemaren cuma 1 doang yang bisa hiks)\n"
updates += "\n"
updates += "Kalo nemu yang aneh2 kontak @araishikeiwai yak"
groups = Lycantulul::Game.all.map(&:group_id).uniq

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates)
      success += 1
      sleep(0.1)
    rescue StandardError => e
      failure += 1
      puts e.message
    end
  end
end

puts "TARGET: #{groups.count}"
puts "OK: #{success}"
puts "NO: #{failure}"
