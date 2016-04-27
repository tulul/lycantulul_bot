load 'Rakefile'

puts "Current stats:"
puts
puts "Games started: #{Lycantulul::Game.count}"
puts "Ranked games played: #{g = Lycantulul::Group.all.sum(&:game)}"
puts "Werewolf victory: #{w = Lycantulul::Group.all.sum(&:werewolf_victory)} (#{"%.2f\%" % (w * 100.0 / g)})"
puts "Villager victory: #{v = Lycantulul::Group.all.sum(&:village_victory)} (#{"%.2f\%" % (v * 100.0 / g)})"
puts
puts "Registered players: #{Lycantulul::RegisteredPlayer.count}"
puts "Registered groups: #{Lycantulul::Group.count}"
puts
puts "Games waiting: #{Lycantulul::Game.where(finished: false, waiting: true).count}"
puts "Games running: #{Lycantulul::Game.running.count}"
