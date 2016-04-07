module Lycantulul
  class NightTimerJob
    include SuckerPunch::Job

    def perform(game)
      LycantululBot.check_round_finished(game, true)
    end
  end
end

