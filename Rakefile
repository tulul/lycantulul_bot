require 'rake'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require File.expand_path('../config/init', __FILE__)
require 'lycantulul_bot'

namespace :lycantulul do
  task :start do
    LycantululBot.start
  end
end

task default: 'lycantulul:start'
