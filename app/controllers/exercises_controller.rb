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
  end
end
