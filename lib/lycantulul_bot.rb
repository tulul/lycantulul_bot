require 'redis'
require 'mongoid'
require 'mongoid-locker'
require 'telegram/bot'
require 'sucker_punch'
require 'active_support/inflector'

require 'lycantulul_bot/game'
require 'lycantulul_bot/group'
require 'lycantulul_bot/player'
require 'lycantulul_bot/registered_player'
require 'lycantulul_bot/statistics'
require 'lycantulul_bot/jobs/discussion_timer_job'
require 'lycantulul_bot/jobs/input_processor_job'
require 'lycantulul_bot/jobs/message_queue_job'
require 'lycantulul_bot/jobs/message_sending_job'
require 'lycantulul_bot/jobs/night_timer_job'
require 'lycantulul_bot/jobs/voting_broadcast_job'
require 'lycantulul_bot/jobs/voting_timer_job'
require 'lycantulul_bot/jobs/welcome_message_job'

module LycantululBot
  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      bot.listen do |message|
        InputProcessorJob.perform_async(message, bot)
      end
    end
  rescue Net::ReadTimeout => e
    puts Time.now.utc
    puts 'TIMEOUT'
    sleep(1)
    retry
  rescue Telegram::Bot::Exceptions::ResponseError => e
    puts Time.now.utc
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    if e.message =~ /429/
      sleep(3)
    end
    retry unless e.message =~ /error_code: .[400|403|409]./
  rescue StandardError => e
    puts Time.now.utc
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    retry
  end

  def self.log(message)
    puts "#{Time.now.utc} -- #{message.gsub("\n", ' || ')}"
  end
end
