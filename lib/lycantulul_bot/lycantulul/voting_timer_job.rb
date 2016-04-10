module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    # list the states with sequence order
    ['start', 'remind', 'remind_again', 'final'].each_with_index do |state, value|
      const_set(state.upcase, value)
    end

    def perform(game, round, state, time)
      next_reminder =
        case state
        when START, REMIND
          time / 2
        when REMIND_AGAIN
          time
        when FINAL
          LycantululBot.log('invoking check voting from job')
          LycantululBot.check_voting_finished(game, round, true)
          nil
        end

      LycantululBot.log('reminding')
      LycantululBot.remind(game, round, time, next_reminder, state)
    end

    def self.next_state(state)
      state + 1
    end
  end
end
