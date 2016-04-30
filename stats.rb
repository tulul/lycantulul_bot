load 'Rakefile'

puts "Current stats:"
puts Time.now.utc
puts
puts "Games started: #{Lycantulul::Game.count}"
puts "Ranked games played: #{g = Lycantulul::Group.all.sum(&:game)}"
puts "Werewolf victory: #{w = Lycantulul::Group.all.sum(&:werewolf_victory)} (#{"%.2f\%" % (w * 100.0 / g)})"
puts "Villager victory: #{v = Lycantulul::Group.all.sum(&:village_victory)} (#{"%.2f\%" % (v * 100.0 / g)})"
puts
puts "Registered players: #{Lycantulul::RegisteredPlayer.count}"
puts "Blocking players: #{Lycantulul::RegisteredPlayer.where(blocked: true).count}"
puts "Registered groups: #{Lycantulul::Group.count}"
puts
puts "Games waiting: #{Lycantulul::Game.where(finished: false, waiting: true).count}"
puts "Games running: #{Lycantulul::Game.running.count}"
puts
puts "Role frequency statistics"

sum = Lycantulul::RegisteredPlayer.all.sum(&:game)
tot = {}
Lycantulul::Game::ROLES.each do |role|
  tot[role] = Lycantulul::RegisteredPlayer.all.sum{ |x| x.send(role) }
end

tot.sort_by{ |_, v| v }.reverse.each do |role, count|
  puts "#{role}: #{"%.2f%" % (count * 100.0 / sum)}"
end
