load 'Rakefile'

while Lycantulul::Game.where(finished: false, waiting: false).count > 0
  sleep(5)
end

res = $redis.get('lycantulul::maintenance').to_i rescue 0
$redis.set('lycantulul::maintenance', res ^ 1)
