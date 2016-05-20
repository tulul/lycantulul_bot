load 'Rakefile'

updates = []
updates << '<b>[Sayembara Tulul]</b>'
updates << 'Hai semua~'
updates << "Mimin Tulul butuh kreativitas kalian untuk membuat logo yang menarik untuk Lycantulul! (iya ini yang dipake sekarang nyomot dari Google \xF0\x9F\x98\x82)"
updates << ''
updates << 'Berikut syarat dan ketentuan logo:'
updates << '- Memiliki unsur serigala'
updates << '- Memiliki unsur tulisan "Lycantulul"'
updates << '- Bagus'
updates << '- Persegi'
updates << ''
updates << 'Berikut syarat dan ketentuan pengiriman:'
updates << '- Logo dengan format <b>.png</b> di-attach pada email'
updates << '- Kirim ke <b>lycantulul@araishikeiwai.com</b> sebelum <b>1 Juni 2016 18.00 WIB</b>'
updates << '- Tuliskan subject "<b>[Logo] Nama Pembuat | @username_telegram</b>" (<i>tanpa tanda kutip, ganti Nama Pembuat dan @username_telegram dengan nama dan username sendiri</i>). Contoh: [Logo] Rick Daniel | @araishikeiwai'
updates << ''
updates << 'Berikut syarat dan ketentuan sayembara:'
updates << '- Logo yang tidak memenuhi syarat-syarat logo dan pengiriman di atas tidak akan diikutsertakan'
updates << '- Boleh mengirimkan lebih dari satu logo'
updates << '- Logo terbaik akan dipilih oleh tim juri dan dipakai di semua hal yang berkaitan dengan Lycantulul'
updates << '- Logo terpilih menjadi hak milik eksklusif Mimin Tulul'
updates << '- Hak milik eksklusif dibeli dengan harga <b>Rp 200.000</b>'
updates << '- Pembuat logo terpilih akan dihubungi Mimin Tulul untuk mengirimkan berkas raw (preferably .svg) dan pengurusan pembayaran'
updates << ''
updates << 'Tim Juri:'
updates << '- Rick Daniel (@araishikeiwai)'
updates << ''
updates << 'Ayo ayo dikirim logonya! Ada hadiah menanti!'
updates << '<i>Kemurahan?</i>'
updates << "YHA ini game-nya nirlaba, mana developer-nya hanya seorang mahasiswa, tinggalnya di ibu kota negara yang semua mahal-mahal harganya \xF0\x9F\x98\xA2"
updates << ''
updates << 'Ditunggu ya~'
updates << "~Mimin Tulul \xF0\x9F\x92\x99"
updates << ''
updates << "- <a href='https://github.com/tulul/lycantulul_bot'>Klik sini kalo mau saran/lapor bug/dll (github)</a>"
updates << "- <a href='https://storebot.me/bot/lycantulul_bot'>Klik sini kalo mau ngasih rating/review (storebot)</a>"
updates << "- <a href='https://telegram.me/lycantulul'>Klik sini kalo grup kalian sepi dan pengen main bareng di grup publik</a>"
updates = updates.join("\n")
puts updates.length

groups = LycantululBot::RegisteredPlayer.all.map(&:user_id).uniq

success = 0
failure = 0

Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    begin
      bot.api.send_message(chat_id: g, text: updates, parse_mode: 'HTML', disable_web_page_preview: true, disable_notification: true)
      success += 1
      sleep(0.05)
    rescue StandardError => e
      if e.message =~ /403/
        LycantululBot::RegisteredPlayer.find_by(user_id: g).update_attribute(:blocked, true) rescue nil
      end
      failure += 1
      puts e.message
    end
  end
end

puts "TARGET: #{groups.count}"
puts "OK: #{success}"
puts "NO: #{failure}"
