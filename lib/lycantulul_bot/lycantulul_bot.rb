class LycantululBot
  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      bot.listen do |message|
        Lycantulul::InputProcessorJob.perform_async(message, bot)
      end
    end
  rescue StandardError => e
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    retry
  end

  def self.log(message)
    puts "#{Time.now.utc} -- #{message}"
  end
end
