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
Lycantulul::Game::ROLES.each do |role|
  puts "#{role}: #{"%.2f%" % ((Lycantulul::RegisteredPlayer.all.sum{ |x| x.send(role) }) * 100.0 / sum)}"
end
