class LycantululBot
  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      bot.listen do |message|
        Lycantulul::InputProcessorJob.perform_async(message, bot)
      end
    end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    if e.message =~ /429/
      sleep(3)
    end
    retry unless e.message =~ /[400|403|409]/
  end

  def self.log(message)
    #puts "#{Time.now.utc} -- #{message}"
  end
end
