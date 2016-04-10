require 'redis'
r = Redis.new
res = r.get('lycantulul::maintenance').to_i rescue 0
r.set('lycantulul::maintenance', res ^ 1)
