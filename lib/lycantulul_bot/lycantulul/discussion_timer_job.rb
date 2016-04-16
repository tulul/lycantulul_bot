module Lycantulul
  class DiscussionTimerJob
    include SuckerPunch::Job

    def perform(game, round, ip)
      ip.log('ending discussion')
      ip.end_discussion_and_start_voting(game, round, true)
    end
  end
end
