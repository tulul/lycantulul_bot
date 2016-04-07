module Lycantulul
  class NightTimerJob
    include SuckerPunch::Job

    def perform(game, round)
      LycantululBot.check_round_finished(game, round, true)
    end
  end
end
