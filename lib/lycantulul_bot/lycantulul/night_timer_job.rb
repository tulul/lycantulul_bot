module Lycantulul
  class NightTimerJob
    include SuckerPunch::Job

    def perform(game, round)
      LycantululBot.log('invoking check round from job')
      LycantululBot.check_round_finished(game, round, true)
    end
  end
end
