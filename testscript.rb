load 'Rakefile'

class Telegram::Bot::Types::User
  def self.bikin(id)
    return self.new(id: id, first_name: id.to_s)
  end

  def pm(text)
    message = Telegram::Bot::Types::Message.new(chat: Telegram::Bot::Types::Chat.new(type: 'private', id: self.id), text: text, from: self, date: Time.now.to_i, message_id: 1)
    LycantululBot.start(message)
  end

  def gr(text)
    message = Telegram::Bot::Types::Message.new(chat: Telegram::Bot::Types::Chat.new(type: 'group', id: 21), text: text, from: self, date: Time.now.to_i, message_id: 1)
    LycantululBot.start(message)
  end
end

def print_game
  puts
  @g.reload
  puts "n: #{@g.night ? 1 : 0} | f: #{@g.finished ? 1 : 0}"
  puts "#{'victim'.ljust(10)}: #{@g.victim.map{ |a| "#{a[:killer_id]}, #{a[:full_name]}" } }"
  puts "#{'seen'.ljust(10)}: #{@g.seen.map{ |a| "#{a[:seer_id]}, #{a[:full_name]}" } }"
  puts "#{'protectee'.ljust(10)}: #{@g.protectee.map{ |a| "#{a[:protector_id]}, #{a[:full_name]}" } }"
  puts "#{'votee'.ljust(10)}: #{@g.votee.map{ |a| "#{a[:voter_id]}, #{a[:full_name]}" } }"
  @g.players.each do |a|
    puts "#{a.user_id} : #{a.role} : #{a.alive ? 1 : 0}"
  end
  puts
end

def event(message)
  puts
  puts ("   #{message}   ".center(159, '#'))
end

def start_vote
  LycantululBot.message_action(game, LycantululBot::VOTING_START)
end

event('reset db')
Lycantulul::Game.all.map(&:destroy)
Lycantulul::Player.all.map(&:destroy)
Lycantulul::RegisteredPlayer.all.map(&:destroy)

event('create users')
a0 = Telegram::Bot::Types::User.bikin(0)
a1 = Telegram::Bot::Types::User.bikin(1)
a2 = Telegram::Bot::Types::User.bikin(2)
a3 = Telegram::Bot::Types::User.bikin(3)
a4 = Telegram::Bot::Types::User.bikin(4)
a5 = Telegram::Bot::Types::User.bikin(5)
a6 = Telegram::Bot::Types::User.bikin(6)
a7 = Telegram::Bot::Types::User.bikin(7)
a8 = Telegram::Bot::Types::User.bikin(8)
a9 = Telegram::Bot::Types::User.bikin(9)
a10 = Telegram::Bot::Types::User.bikin(10)
a11 = Telegram::Bot::Types::User.bikin(11)
a12 = Telegram::Bot::Types::User.bikin(12)
a13 = Telegram::Bot::Types::User.bikin(13)
a14 = Telegram::Bot::Types::User.bikin(14)
a15 = Telegram::Bot::Types::User.bikin(15)

event('registration')
a0.pm('/daftar')
a1.pm('/daftar')
a2.pm('/daftar')
a3.pm('/daftar')
a4.pm('/daftar')
a5.pm('/daftar')
a6.pm('/daftar')
a7.pm('/daftar')
a8.pm('/daftar')
a9.pm('/daftar')
a10.pm('/daftar')
a11.pm('/daftar')
a12.pm('/daftar')
a13.pm('/daftar')
a14.pm('/daftar')
a15.pm('/daftar')

# event('invalid commands')
# a0.gr('/daftar')
# a0.gr('/batalin')
# a0.gr('/gajadi')
# a0.gr('/ikutan')
# a0.gr('/mulai_main')
# a0.gr('/siapa_aja')
# a0.gr('/panggil_semua')
# a0.gr('/panggil_yang_idup')
# a0.gr('/ilangin_keyboard')

# event('cancel')
# a0.gr('/bikin_baru')
# a0.gr('/batalin')

# event('everyone leaves')
# a0.gr('/bikin_baru')
# a1.gr('/ikutan')
# a0.gr('/gajadi')
# a1.gr('/gajadi')

# event('not enough players')
# a0.gr('/bikin_baru')
# a1.gr('/ikutan')
# a1.gr('/mulai_main')

event('start game')
a0.gr('/bikin_baru')
a1.gr('/ikutan')
a2.gr('/ikutan')
a3.gr('/ikutan')
a4.gr('/ikutan')
a5.gr('/ikutan')
a6.gr('/ikutan')
a7.gr('/ikutan')
a8.gr('/ikutan')
a9.gr('/ikutan')
a10.gr('/ikutan')
a11.gr('/ikutan')
a12.gr('/ikutan')
a13.gr('/ikutan')
a14.gr('/ikutan')
a15.gr('/ikutan')
a0.gr('/mulai_main')

# event('cant action to self')
# a0.pm('0')
# a1.pm('1')
# a2.pm('2')
# a3.pm('3')
# a4.pm('4')
# a5.pm('5')
# a6.pm('6')
# a7.pm('7')
# a8.pm('8')
# a9.pm('9')
# a10.pm('10')
# a11.pm('11')
# a12.pm('12')
# a13.pm('13')
# a14.pm('14')
# a15.pm('15')

event('modify game contents')
@g = Lycantulul::Game.find_by(group_id: 21, finished: false, night: true, waiting: false)
@g.restart
@g.update_attribute(:waiting, false)
@g.players.with_id(0).assign(Lycantulul::Game::WEREWOLF)
@g.players.with_id(1).assign(Lycantulul::Game::WEREWOLF)
@g.players.with_id(2).assign(Lycantulul::Game::WEREWOLF)
@g.players.with_id(3).assign(Lycantulul::Game::SEER)
@g.players.with_id(4).assign(Lycantulul::Game::SEER)
@g.players.with_id(5).assign(Lycantulul::Game::PROTECTOR)
@g.players.with_id(6).assign(Lycantulul::Game::NECROMANCER)
@g.players.with_id(7).assign(Lycantulul::Game::SILVER_BULLET)
print_game

# event('werewolves no majority vote')
# a0.pm('5')
# a1.pm('6')
# a2.pm('7')
# a3.pm('8')
# print_game

# event('voting no majority vote')
# start_vote
# a0.pm('1')
# a1.pm('2')
# a2.pm('3')
# a3.pm('4')
# a4.pm('5')
# a5.pm('6')
# a6.pm('7')
# a7.pm('8')
# a8.pm('9')
# a9.pm('0')
# print_game

# event('werewolves kill successful')
# a0.pm('5')
# a1.pm('5')
# a2.pm('6')
# a3.pm('7')
# print_game

# event('execute innocent')
# start_vote
# a0.pm('6')
# a1.pm('6')
# a2.pm('6')
# a3.pm('6')
# a4.pm('6')
# a6.pm('3')
# a7.pm('6')
# a8.pm('6')
# a9.pm('6')
# print_game

# event('under protection of jimat')
# a0.pm('7')
# a1.pm('7')
# a2.pm('7')
# a3.pm('7')
# print_game

# event('execute werewolf')
# start_vote
# a0.pm('1')
# a1.pm('0')
# a2.pm('0')
# a3.pm('0')
# a4.pm('0')
# a7.pm('0')
# a8.pm('0')
# a9.pm('0')
# print_game

# event('seen killed by werewolves')
# a1.pm('7')
# a2.pm('7')
# a3.pm('2')
# print_game

# event('execute no one')
# start_vote
# a1.pm('8')
# a2.pm('8')
# a3.pm('8')
# a4.pm('1')
# a8.pm('1')
# a9.pm('1')
# print_game

# event('seer killed by werewolves')
# a1.pm('2')
# a2.pm('9')
# a3.pm('4')
# print_game

# event('execute innocent')
# start_vote
# a1.pm('9')
# a3.pm('9')
# a4.pm('9')
# a8.pm('9')
# a9.pm('8')
# print_game

# event('jimat protects werewolf, dies, werewolf wins')
# a1.pm('8')
# a3.pm('1')
# print_game

event('werewolves kill silver bullet')
a0.pm('7')
a1.pm('7')
a2.pm('7')
a3.pm('15')
a4.pm('15')
a5.pm('15')
a6.pm(Lycantulul::Game::NECROMANCER_SKIP)
print_game

event('execute innocent')
a0.pm('8')
a1.pm('8')
a2.pm('8')
a3.pm('8')
a4.pm('8')
a5.pm('8')
a6.pm('8')
a7.pm('8')
a8.pm('9')
a9.pm('8')
a10.pm('8')
a11.pm('8')
a12.pm('8')
a13.pm('8')
a14.pm('8')
a15.pm('8')

event('necromancer raises someone')
@g.players.with_id(0).kill
@g.players.with_id(1).kill
@g.players.with_id(2).kill
@g.players.with_id(3).kill
@g.players.with_id(4).kill
@g.players.with_id(5).kill
a6.pm('1')
print_game

event('execute innocent')
a0.pm('9')
a1.pm('9')
a2.pm('9')
a3.pm('9')
a4.pm('9')
a5.pm('9')
a6.pm('9')
a7.pm('9')
a8.pm('9')
a9.pm('10')
a10.pm('9')
a11.pm('9')
a12.pm('9')
a13.pm('9')
a14.pm('9')
a15.pm('9')

event('necromancer killed before raising')
@g.players.with_id(0).revive
@g.players.with_id(1).revive
@g.players.with_id(2).revive
@g.players.with_id(3).kill
@g.players.with_id(4).kill
@g.players.with_id(5).kill
@g.players.with_id(6).revive
a0.pm('6')
a1.pm('6')
a2.pm('6')
a6.pm('9')
print_game

event('reset db')
Lycantulul::Game.all.map(&:destroy)
Lycantulul::Player.all.map(&:destroy)
Lycantulul::RegisteredPlayer.all.map(&:destroy)
