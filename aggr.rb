load 'Rakefile'

hash = Lycantulul::Game.where(:created_at.ne => nil).group_by{|k| k.created_at.to_date.to_s}.map{|k,v| [k, v.count]}.sort_by{|x| x[0]}.map{|k| [k[0], [k[1]]]}.to_h
Lycantulul::RegisteredPlayer.where(:created_at.ne => nil).group_by{|k| k.created_at.to_date.to_s}.map{|k,v| [k, v.count]}.sort_by{|x| x[0]}.each do |date, count|
  hash[date] << count
end

sum_g = 0
sum_p = 0
hash.sort_by{|k,v| k}.each do |k,v|
  sum_g += v[0]
  sum_p += v[1]
  puts "#{k}\t#{v[0]}\t#{v[1]}\t#{sum_g}\t#{sum_p}"
end
