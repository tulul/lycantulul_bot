# Tululised Werewolf Moderator Bot

inspired by [WerewolfBot](https://telegram.me/werewolfbot)

[play me!](https://telegram.me/lycantulul_bot)

### Daftar Perintah
- `/start` - Mulai berhubungan dan mendaftarkan diri
- `/help` - Liat petunjuk (link ke github doang ini)
- `/bikin_baru` - Bikin game baru
- `/batalin` - Batalin game
- `/ikutan` - Ikutan main
- `/gajadi` - Ga jadi ikutan main
- `/mulai_main` - Mulai main
- `/siapa_aja` - Liat siapa aja yang lagi main
- `/hasil_voting` - Liat hasil voting sementara
- `/panggil_semua` - Panggil semua pemain
- `/panggil_yang_idup` - cukup jelas
- `/panggil_yang_belom_voting` - cukup jelas
- `/ilangin_keyboard` - Reply keyboard muncul terus? Cobain nih

### Penjelasan Peran
1. Warga Kampung 

   Pola kemunculan: selalu ada, sisa pemain yang tidak dapat peran.
  
   Tugas & Penjelasan: 
   - Dibunuh dan ikut voting eksekusi.
   - Bisa tidak dibunuh serigala jika dilindungi Penjual Jimat.

2. TTS (Tulul-Tulul Serigala)

   Pola kemunculan: selalu ada, bertambah setiap 5 pemain (5 pemain: 1 TTS, 10 pemain: 2 TTS, dst.).
  
   Tugas & Penjelasan: 
   - Membunuh semua yang bukan TTS.
   - Jika ada lebih dari 1 TTS, maka proses membunuh adalah voting antara para TTS. Jika tidak ada suara yang mayoritas, tidak ada yang mati.
   - Jika membunuh seseorang yang dilindungi Penjual Jimat, korban tidak akan mati.
   - Jika membunuh Pengidap Ebola, salah satu serigala yang masih hidup akan ikut mati (dipilih secara acak).

3. Tukang Ngintip

   Pola kemunculan: muncul saat jumlah pemain 6 orang, bertambah setiap 12 pemain (6 pemain: 1 Tukang Ngintip, 18 pemain: 2 Tukang Ngintip, dst.).
  
   Tugas & Penjelasan:
   - Mengintip peran pemain lain.
   - Jika yang diintip dibunuh TTS, tidak dikasih tahu.
   - Jika si Tukang Intip dibunuh TTS, tidak dikasih tahu.
  
4. Penjual Jimat
  
   Pola kemunculan: muncul saat jumlah pemain 8 orang, bertambah setiap 14 pemain (8 pemain: 1 Penjual Jimat, 22 pemain: 2 Penjual Jimat, dst.).
  
   Tugas & Penjelasan:
   - Melindungi salah satu pemain dari dibunuh TTS.
   - Jika yang dilindungi adalah TTS, ada 25% kemungkinan si Penjual Jimat akan mati.

5. Mujahid
  
   Pola kemunculan: muncul saat jumlah pemain 12 orang, hanya ada 1 Mujahid
  
   Tugas & Penjelasan:
   - Menghidupkan salah satu pemain yang sudah mati.
   - Sebagai gantinya, si Mujahid akan mati.

6. Pengidap Ebola
  
   Pola kemunculan: muncul saat jumlah pemain 14 orang, bertambah setiap 10 pemain (14 pemain: 1 Pengidap Ebola, 24 pemain: 2 Pengidap Ebola, dst.).
  
   Tugas & Penjelasan:
   - Sama seperti Warga Kampung.
   - Jika dibunuh TTS, maka salah satu dari TTS akan ikut mati (dipilih secara acak).

### Akhir Permainan

Permainan berakhir saat:
- Tidak ada lagi yang bisa dibunuh oleh TTS (jumlah TTS yang hidup lebih banyak atau sama dengan jumlah pemain non-TTS yang hidup). Kemenangan bagi TTS.
- Semua TTS sudah mati dieksekusi. Kemenangan bagi warga.
