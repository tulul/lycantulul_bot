# Tululised Werewolf Moderator Bot

inspired by [WerewolfBot](https://telegram.me/werewolfbot)

[play me in public group!](https://telegram.me/lycantulul)
[or add the bot to your group!](https://telegram.me/lycantulul_bot)

### Daftar Perintah
- `/start` - Mulai berhubungan dan mendaftarkan diri
- `/help` - Liat petunjuk (link ke github doang ini)
- `/bikin_baru` - Bikin game baru
- `/batalin` - Batalin game
- `/ikutan` - Ikutan main
- `/gajadi` - Ga jadi ikutan main
- `/ganti_settingan_peran` - Ngubah jumlah salah satu dari peran
- `/batal_nyetting_peran` - Batalin settingan peran yang lagi di-setting sekarang
- `/apus_settingan_peran` - Apus semua settingan peran yang udah dibikin
- `/mulai_main` - Mulai main
- `/siapa_aja` - Liat siapa aja yang lagi main
- `/hasil_voting` - Liat hasil voting sementara
- `/panggil_semua` - Panggil semua pemain
- `/panggil_yang_idup` - cukup jelas
- `/panggil_yang_belom_voting` - cukup jelas
- `/ganti_waktu_malam` - atur batas waktu malam buat action
- `/ganti_waktu_voting` - atur batas waktu voting
- `/ganti_waktu_diskusi` - atur batas waktu diskusi
- `/statistik_grup` - Liat statistik grup
- `/statistik` - Liat statistik diri sendiri
- `/ilangin_keyboard` - Reply keyboard muncul terus? Cobain nih

### Peran

#### Penjelasan Tugas Peran

##### Warga Biasa (pasif)
1. Warga Kampung
   - Dibunuh dan ikut voting eksekusi.
1. Pak Raden
   - Dibunuh dan ikut voting eksekusi.
   - Saat voting, bobot suaranya 3.
1. Pak Ogah
   - Dibunuh dan ikut voting eksekusi.
   - Saat voting, bobot suaranya 0.
1. Anak Presiden
   - Dibunuh dan ikut voting eksekusi.
   - Tidak akan mati saat dieksekusi pertama kali.
1. Dukun
   - Diberitahu peran salah satu pemain yang masih hidup (seperti tukang ngintip, tapi ga bisa milih).
   - Karena random, tidak ada jaminan pemain yang sudah diberitahu tidak diberitahu lagi.
1. Tamaki Shinichi
   - Setiap malam akan diberitahu siapa yang akan dibunuh oleh para TTS.
1. Pengidap Ebola
   - Sama seperti Warga Kampung.
   - Jika dibunuh TTS, maka salah satu dari TTS akan ikut mati (dipilih secara acak).

##### Warga sakti (aktif)
1. Tukang Ngintip
   - Mengintip peran pemain lain.
1. Penjual Jimat
   - Melindungi salah satu pemain dari dibunuh TTS.
   - Jika yang dilindungi adalah TTS, ada 25% kemungkinan si Penjual Jimat akan mati.
1. Mujahid
   - Menghidupkan salah satu pemain yang sudah mati.
   - Sebagai gantinya, si Mujahid akan mati.
1. Super Mujahid
   - Menghidupkan salah satu pemain yang sudah mati.
   - Setelah menghidupkan, si Super Mujahid masih tetap hidup (dan tidak diberitahu ke publik).

##### Penjahat
1. TTS (Tulul-Tulul Serigala)
   - Membunuh semua yang bukan TTS.
   - Jika ada lebih dari 1 TTS, maka proses membunuh adalah voting antara para TTS. Jika tidak ada suara yang mayoritas, tidak ada yang mati.
   - Jika membunuh seseorang yang dilindungi Penjual Jimat, korban tidak akan mati.
   - Jika membunuh Pengidap Ebola, salah satu serigala yang masih hidup akan ikut mati (dipilih secara acak).

#### Jumlah dan Pola Kemunculan Peran

1. Warga Kampung: selalu ada, sisa pemain yang tidak dapat peran.
1. TTS (Tulul-Tulul Serigala): selalu ada, bertambah setiap 5 pemain (5 pemain: 1 TTS, 10 pemain: 2 TTS, dst.).
1. Tukang Ngintip: muncul saat jumlah pemain 6 orang, bertambah setiap 12 pemain (6 pemain: 1 Tukang Ngintip, 18 pemain: 2 Tukang Ngintip, dst.).
1. Penjual Jimat: muncul saat jumlah pemain 8 orang, bertambah setiap 14 pemain (8 pemain: 1 Penjual Jimat, 22 pemain: 2 Penjual Jimat, dst.).
1. Pengidap Ebola: muncul saat jumlah pemain 14 orang, bertambah setiap 10 pemain (14 pemain: 1 Pengidap Ebola, 24 pemain: 2 Pengidap Ebola, dst.).
1. Tamaki Shinichi: muncul saat jumlah pemain 16 orang
1. Pak Ogah: muncul saat jumlah pemain 9 orang
1. Pak Raden: muncul saat jumlah pemain 11 orang
1. Mujahid: muncul saat jumlah pemain 12 orang
1. Dukun: muncul saat jumlah pemain 14 orang
1. Anak Presiden: muncul saat jumlah pemain 15 orang
1. Super Mujahid: muncul saat jumlah pemain 18 orang

Rujukan daftar peran sampai 20 pemain:
5: 1 TTS
6: 1 TTS, 1 Tukang Ngintip
7: 1 TTS, 1 Tukang Ngintip
8: 1 TTS, 1 Tukang Ngintip, 1 Penjual Jimat
9: 1 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah
10: 2 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah 
11: 2 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden
12: 2 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid
13: 2 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid
14: 2 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun
15: 3 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden
16: 3 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden, 1 Tamaki Shinichi
17: 3 TTS, 1 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden, 1 Tamaki Shinichi
18: 3 TTS, 2 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden, 1 Tamaki Shinichi, 1 Super Mujahid
19: 3 TTS, 2 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden, 1 Tamaki Shinichi, 1 Super Mujahid
20: 4 TTS, 2 Tukang Ngintip, 1 Penjual Jimat, 1 Pak Ogah, 1 Pak Raden, 1 Mujahid, 1 Pengidap Ebola, 1 Dukun, 1 Anak Presiden, 1 Tamaki Shinichi, 1 Super Mujahid

Jika tidak puas dengan komposisi di atas, silakan diatur sendiri menggunakan perintah /ganti_settingan_peran

### Akhir Permainan

Permainan berakhir saat:
- Tidak ada lagi yang bisa dibunuh oleh TTS (jumlah TTS yang hidup lebih banyak atau sama dengan jumlah pemain non-TTS yang hidup). Kemenangan bagi TTS.
- Semua TTS sudah mati dieksekusi. Kemenangan bagi warga.
