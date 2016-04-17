load 'Rakefile'

res = $redis.get('lycantulul::maintenance').to_i rescue 0

while res == 0 && Lycantulul::Game.where(finished: false, waiting: false).count > 0
  sleep(5)
end

$redis.set('lycantulul::maintenance', res ^ 1)
