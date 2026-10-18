module ExercisesHelper
  # Filter chips are links so that the state lives in the URL: a refresh, a
  # bookmark and the back button all keep the current filter. The frame they sit
  # in advances the URL, so clicking one does not reload the page.
  def filter_chip(label, difficulty:, topic:, active:)
    link_to label, root_path(difficulty: difficulty, topic: topic),
      class: class_names("chip", "chip--on": active),
      aria: { current: ("true" if active) }
  end

  def filtering?
    @difficulty.present? || @topic.present?
  end
end
