module Lycantulul
  class DiscussionTimerJob
    include SuckerPunch::Job

    def perform(game)
      LycantululBot.message_action(game, LycantululBot::VOTING_START)
    end
  end
end
