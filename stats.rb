load 'Rakefile'

puts "Current stats:"
puts
puts "Games played: #{Lycantulul::Game.count}"
puts "Registered players: #{Lycantulul::RegisteredPlayer.count}"
puts "Registered groups: #{Lycantulul::Group.count}"
puts
puts "Games waiting: #{Lycantulul::Game.where(finished: false, waiting: true).count}"
puts "Games running: #{Lycantulul::Game.running.count}"
