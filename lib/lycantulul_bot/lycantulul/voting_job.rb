module Lycantulul
  class VotingJob
    include SuckerPunch::Job

    def perform(game)
      LycantululBot.message_action(game, LycantululBot::VOTING_START)
    end
  end
end
