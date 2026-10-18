# What one user has done with a set of exercises, loaded in two queries rather
# than one per card.
#
# The library renders a dozen cards and will render more; asking each card for
# its own attempts is the obvious way to write this and the reason list pages
# get slow. Both lookups are grouped counts over the whole page at once.
#
# Scoped to a single user by construction. There is no way to call this that
# reads another person's attempts, which is the point: "status reflects the
# signed-in user's attempts only" should be a property of the object, not a
# where clause someone has to remember.
class AttemptSummary
  def self.for(user, exercises)
    return none if user.nil?

    scope = Attempt.where(user: user, exercise: exercises)

    new(scope.group(:exercise_id).count, scope.solved.group(:exercise_id).count)
  end

  def self.none
    new({}, {})
  end

  def initialize(counts, solved_counts)
    @counts = counts
    @solved_counts = solved_counts
  end

  def attempted?(exercise)
    count(exercise).positive?
  end

  def solved?(exercise)
    @solved_counts.fetch(exercise.id, 0).positive?
  end

  def count(exercise)
    @counts.fetch(exercise.id, 0)
  end
end
