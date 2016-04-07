require 'rake'
require 'redis'
require 'mongoid'
require 'telegram/bot'
require 'sucker_punch'

require File.dirname(__FILE__) + '/config/init.rb'
Dir[File.dirname(__FILE__) + '/lib/lycantulul_bot/*/*.rb'].each{ |file| require file }
Dir[File.dirname(__FILE__) + '/lib/lycantulul_bot/**/*.rb'].each{ |file| require file }

$redis = Redis.new
Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml', :production)

namespace :lycantulul do
  task :start do
    LycantululBot.start
  end
end

task default: 'lycantulul:start'
