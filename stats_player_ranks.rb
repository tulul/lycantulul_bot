load 'Rakefile'
Lycantulul::RegisteredPlayer.all.sort_by(&:game).each{|x| puts "#{"%-3d" % x.game} #{x.full_name}"}; nil
