module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    START = 0
    REMIND = 1
    REMIND_AGAIN = 2
    FINAL = 3

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
      case state
      when START
        REMIND
      when REMIND
        REMIND_AGAIN
      when REMIND_AGAIN
        FINAL
      end
    end
  end
end
