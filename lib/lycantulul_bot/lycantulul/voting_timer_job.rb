module Lycantulul
  class VotingTimerJob
    include SuckerPunch::Job

    START = 0
    REMIND = 1
    REMIND_AGAIN = 2
    FINAL = 3

    def perform(game, round, state, time)
      case state
      when START
        LycantululBot.log('first reminder')
        LycantululBot.remind(game, round, time)
        Lycantulul::VotingTimerJob.perform_in(time / 2, round, REMIND, time / 2)
      when REMIND
        LycantululBot.log('second reminder')
        LycantululBot.remind(game, round, time)
        Lycantulul::VotingTimerJob.perform_in(time / 2, round, REMIND_AGAIN, time / 2)
      when REMIND_AGAIN
        LycantululBot.log('third reminder')
        LycantululBot.remind(game, round, time)
        Lycantulul::VotingTimerJob.perform_in(time, round, FINAL, time)
      when FINAL
        LycantululBot.log('invoking check voting from job')
        LycantululBot.check_voting_finished(game, round, true)
      end
    end
  end
end
