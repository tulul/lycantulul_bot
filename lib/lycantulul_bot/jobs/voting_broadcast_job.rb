module LycantululBot
  class VotingBroadcastJob
    include SuckerPunch::Job

    def perform(game, ip)
      ip.send_voting_broadcast(game)
    end
  end
end
