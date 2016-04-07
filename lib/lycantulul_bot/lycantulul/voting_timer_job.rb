module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    def perform(game, round)
      LycantululBot.log('invoking check voting from job')
      LycantululBot.check_voting_finished(game, round, true)
    end
  end
end
