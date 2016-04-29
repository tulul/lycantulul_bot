class LycantululBot
  def self.start(message)
    Lycantulul::InputProcessorJob.perform_async(message, nil)
  end

  def self.log(message)
    puts "#{Time.now.utc} -- #{message.gsub("\n", ' ||| ')}"
  end
end
