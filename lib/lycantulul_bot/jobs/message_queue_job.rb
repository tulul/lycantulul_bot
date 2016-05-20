module LycantululBot
  class MessageQueueJob
    include SuckerPunch::Job

    def perform(bot, options)
      retry_count = 0
      begin
        bot.api.send_message(options)
      rescue Faraday::TimeoutError => e
        puts Time.now.utc
        puts 'TIMEOUT'
        sleep(2)
        retry
      rescue Telegram::Bot::Exceptions::ResponseError => e
        puts Time.now.utc
        puts e.message
        puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
        puts "retrying: #{retry_count}"

        if e.message =~ /429/
          sleep(3)
        elsif e.message =~ /403/
          RegisteredPlayer.find_by(user_id: message.chat.id).update_attribute(:blocked, true) rescue nil
        end
        retry if e.message !~ /[400|403|409]/ && (retry_count += 1) < 20
      end
    end
  end
end

