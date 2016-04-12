class LycantululBot
  def self.start(message)
    Lycantulul::InputProcessorJob.perform_async(message, nil)
  rescue StandardError => e
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
    retry
  end

  def self.log(message)
    puts "#{Time.now.utc} -- #{message.gsub("\n", ' ||| ')}"
  end
end
