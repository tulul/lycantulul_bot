class LycantululBot
  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      bot.listen do |message|
        Lycantulul::InputProcessorJob.perform_async(message, bot)
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
