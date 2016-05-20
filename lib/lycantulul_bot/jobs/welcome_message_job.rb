module LycantululBot
  class WelcomeMessageJob
    include SuckerPunch::Job

    def perform(game, ip)
      ip.send_welcome_message(game)
    end
  end
end
