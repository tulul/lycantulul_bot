module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    def perform(game, round)
      LycantululBot.check_voting_finished(game, round, true)
    end
  end
end
