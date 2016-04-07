module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    def perform(game)
      LycantululBot.check_voting_finished(game, true)
    end
  end
end
