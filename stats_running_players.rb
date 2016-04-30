load 'Rakefile'
Lycantulul::Game.running.map(&:players).each{|x| puts x.map(&:full_name); puts }; nil
