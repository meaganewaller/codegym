class ExercisesController < ApplicationController
  def index
    @difficulty = params[:difficulty].presence
    @topic = params[:topic].presence

    @exercises = Exercise.published
      .with_difficulty(@difficulty)
      .with_topic(@topic)
      .newest_first

    # Offered as filter options rather than every topic in the table, so a topic
    # that exists only on a scheduled exercise is not advertised early.
    @topics = Exercise.published.topics

    # Built once for the page rather than per card. Signed out, this is empty
    # and no badges render.
    @attempts = AttemptSummary.for(current_user, @exercises)
  end

  def show
    # Scoped to published, so an exercise scheduled for a future date 404s
    # instead of being readable early by anyone who guesses the slug. Raising
    # RecordNotFound is what makes it a 404 rather than a redirect, which
    # codegym-wwd asks for: a redirect would confirm the slug exists.
    @exercise = Exercise.published.find_by!(slug: params[:slug])
  end
end
