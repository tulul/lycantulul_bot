load 'Rakefile'
Lycantulul::Group.all.sort_by(&:game).each{|x| puts "#{"%-3d" % x.game} #{x.title}"}; nil
