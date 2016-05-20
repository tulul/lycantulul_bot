module LycantululBot
  class NightTimerJob
    include SuckerPunch::Job

    def perform(game, round, ip)
      ip.log('invoking check round from job')
      ip.check_round_finished(game, round, true)
    end
  end
end
