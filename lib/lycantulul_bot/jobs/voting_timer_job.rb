module LycantululBot
  class VotingTimerJob
    include SuckerPunch::Job

    # list the states with sequence order
    ['start', 'remind', 'remind_again', 'final'].each_with_index do |state, value|
      const_set(state.upcase, value)
    end

    def perform(game, round, state, time, ip)
      next_reminder =
        case state
        when START, REMIND
          time / 2
        when REMIND_AGAIN
          time
        when FINAL
          ip.log('invoking check voting from job')
          ip.check_voting_finished(game, round, true)
          nil
        end

      ip.log('reminding')
      ip.remind(game, round, time, next_reminder, state)
    end

    def self.next_state(state)
      state + 1
    end
  end
end
