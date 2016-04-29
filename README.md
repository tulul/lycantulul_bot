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
- `/ganti_settingan_voting` - Ngubah voting publik atau rahasia
- `/mulai_main` - Mulai main
- `/siapa_aja` - Liat siapa aja yang lagi main
- `/hasil_voting` - Liat hasil voting sementara
- `/panggil_semua` - Panggil semua pemain
- `/panggil_yang_idup` - cukup jelas
- `/panggil_yang_belom_voting` - cukup jelas
- `/ganti_settingan_waktu` - Ngubah waktu (malam, diskusi, voting)
- `/batal_nyetting_waktu` - Batalin settingan waktu yang lagi di-setting sekarang
- `/statistik_grup` - Liat statistik grup
- `/statistik` - Liat statistik diri sendiri
- `/ilangin_keyboard` - Reply keyboard muncul terus? Cobain nih

### Kustomisasi

Demi fleksibilitas dalam bermain, bot ini menyediakan pilihan untuk mengubah pengaturan permainan sebagai berikut:
- **/ganti\_settingan\_peran** - Digunakan untuk mengganti jumlah peran dalam permainan. _Tidak disarankan karena dapat merusak keseimbangan permainan yang telah dirancang_. Cukup berguna saat ingin mencoba memainkan suatu peran tertentu.
- **/ganti\_settingan\_voting** - Digunakan untuk mengganti sistem voting dari rahasia menjadi publik (dan sebaliknya). Pada sistem rahasia, bot hanya memberitahu seseorang telah melakukan voting dan siapa yang di-vote. Pada sistem publik, bot memberitahu nama seseorang yang telah voting tersebut. _Tidak disarankan karena dapat memberitahu beberapa peran tertentu (seperti Pak Ogah/Pak Raden)_.
- **/ganti\_settingan\_waktu** - Digunakan untuk mengganti waktu permainan. Masing-masing pengaturan waktu memiliki batas minimal 10 detik dan maksimal 300 detik. Ada tiga waktu permainan yang dapat diganti:
   - waktu malam hari
   - waktu diskusi
   - waktu voting

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
   - Setiap malam diberitahu peran salah satu pemain yang masih hidup (seperti Tukang Ngintip, tapi ga bisa milih).
   - Keunggulannya dibanding Tukang Ngintip, diberitahu perannya saat malam hari, jadi ada jaminan akan tahu peran seseorang setiap malam.
   - Karena random, tidak ada jaminan pemain yang sudah diberitahu tidak diberitahu lagi.
1. Tamaki Shinichi
   - Setiap malam akan diberitahu siapa yang akan dibunuh oleh para TTS.
1. Pengidap Ebola
   - Sama seperti Warga Kampung.
   - Jika dibunuh serigala, maka salah satu dari TTS akan ikut mati (dipilih secara acak).

##### Warga sakti (aktif)
1. Tukang Ngintip
   - Mengintip peran pemain lain.
1. Penjual Jimat
   - Melindungi salah satu pemain dari dibunuh serigala.
   - Jika yang dilindungi adalah TTS, ada 25% kemungkinan si Penjual Jimat akan mati.
1. Mujahid
   - Menghidupkan salah satu pemain yang sudah mati.
   - Sebagai gantinya, si Mujahid akan mati.
1. Super Mujahid
   - Menghidupkan salah satu pemain yang sudah mati.
   - Setelah menghidupkan, si Super Mujahid masih tetap hidup (dan tidak diberitahu ke publik).
1. Gelandangan
   - Menumpang di rumah warga lain jadi imun terhadap serangan langsung serigala.
   - Apabila menumpang di rumah serigala dan akan dibunuh serigala, tidak mati.
   - Apabila menumpang di rumah serigala (tapi tidak diincar serigala) atau warga yang dibunuh serigala, maka mati.

##### Penjahat
1. TTS (Tulul-Tulul Serigala)
   - Membunuh semua yang bukan serigala.
   - Jika ada lebih dari 1 serigala, maka proses membunuh adalah voting antara para serigala. Jika tidak ada suara yang mayoritas, tidak ada yang mati.
   - Jika membunuh Pengidap Ebola, salah satu TTS yang masih hidup akan ikut mati (dipilih secara acak).
1. PPS (Pinter-Pinter Serigala)
   - TTS yang punya suara 2 saat voting antar serigala siapa yang mau dibunuh.
   - Tidak akan dipilih ikut mati saat membunuh Pengidap Ebola.
   - Tidak akan didengar oleh Tamaki Shinichi saat ingin membunuh seseorang.
   - Akan terlihat sebagai warga (salah satu peran yang masih hidup) oleh Tukang Ngintip dan Dukun.
   - Peluang Penjual Jimat mati saat menjual jimat ke PPS menjadi 75%.

#### Jumlah dan Pola Kemunculan Peran

1. Warga Kampung: selalu ada, sisa pemain yang tidak dapat peran.
1. TTS (Tulul-Tulul Serigala): selalu ada, bertambah setiap 5 pemain (5 pemain: 1 TTS, 10 pemain: 2 TTS, dst.).
1. Tukang Ngintip: muncul saat jumlah pemain 6 orang, bertambah setiap 12 pemain (6 pemain: 1 Tukang Ngintip, 18 pemain: 2 Tukang Ngintip, dst.).
1. Penjual Jimat: muncul saat jumlah pemain 8 orang, bertambah setiap 14 pemain (8 pemain: 1 Penjual Jimat, 22 pemain: 2 Penjual Jimat, dst.).
1. Pengidap Ebola: muncul saat jumlah pemain 14 orang, bertambah setiap 10 pemain (14 pemain: 1 Pengidap Ebola, 24 pemain: 2 Pengidap Ebola, dst.).
1. Pak Ogah: muncul saat jumlah pemain 9 orang
1. Pak Raden: muncul saat jumlah pemain 11 orang
1. Mujahid: muncul saat jumlah pemain 12 orang
1. Dukun: muncul saat jumlah pemain 14 orang
1. Anak Presiden: muncul saat jumlah pemain 15 orang
1. Tamaki Shinichi: muncul saat jumlah pemain 16 orang
1. Gelandangan: muncul saat jumlah pemain 16 orang
1. Super Mujahid: muncul saat jumlah pemain 18 orang
1. Pinter-Pinter Serigala: muncul saat jumlah pemain 18 orang

### Akhir Permainan

Permainan berakhir saat:
- Tidak ada lagi yang bisa dibunuh oleh serigala (jumlah serigala yang hidup lebih banyak atau sama dengan jumlah pemain non-serigala yang hidup). Kemenangan bagi serigala.
- Semua serigala sudah mati dieksekusi. Kemenangan bagi warga.
