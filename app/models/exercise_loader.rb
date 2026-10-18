# Loads the exercises authored as Markdown under db/exercises/ into the
# exercises table. The files are the source of truth and the table is a
# projection of them; see docs/decisions/0002-exercises-as-files.md.
class ExerciseLoader
  class InvalidExercise < StandardError; end

  PERMITTED_KEYS = %w[slug title summary difficulty topic minutes published_at].freeze
  REQUIRED_KEYS = (PERMITTED_KEYS - %w[published_at]).freeze

  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m

  Result = Struct.new(:created, :updated, :unchanged, keyword_init: true) do
    def total
      created + updated + unchanged
    end

    def to_s
      "#{total} exercises (#{created} created, #{updated} updated, #{unchanged} unchanged)"
    end
  end

  def self.default_directory
    Rails.root.join("db/exercises")
  end

  def self.load_all(directory: default_directory)
    new(directory).load_all
  end

  def initialize(directory)
    @directory = Pathname.new(directory)
  end

  # Coach notes sit beside the exercise they belong to, and nothing in the
  # database may ever carry a solution. Rejecting *.coach.md here makes that a
  # property of the glob rather than something each caller has to remember.
  def exercise_paths
    Pathname.glob(@directory.join("*.md"))
      .reject { |path| path.to_s.end_with?(".coach.md") }
      .sort
  end

  # One transaction for the whole directory: a malformed file part way through
  # would otherwise leave the table half updated, with no indication of which
  # half. db:seed is meant to be safe to run at any time, so it either applies
  # every file or none of them.
  def load_all
    result = Result.new(created: 0, updated: 0, unchanged: 0)

    Exercise.transaction do
      exercise_paths.each do |path|
        attributes = parse(path)
        exercise = Exercise.find_or_initialize_by(slug: attributes["slug"])
        created = exercise.new_record?

        exercise.assign_attributes(attributes)
        changed = exercise.changed?
        save(exercise, path)

        if created
          result.created += 1
        elsif changed
          result.updated += 1
        else
          # Active Record issues no UPDATE for an unchanged record, so a second
          # run leaves updated_at alone. That is what makes db:seed idempotent.
          result.unchanged += 1
        end
      end
    end

    result
  end

  private
    def save(exercise, path)
      exercise.save!
    rescue ActiveRecord::RecordInvalid => error
      raise InvalidExercise,
        "#{path.basename}: #{error.record.errors.full_messages.to_sentence}"
    end

    def parse(path)
      match = FRONT_MATTER.match(path.read)
      raise InvalidExercise, "#{path.basename}: no YAML front matter" if match.nil?

      front_matter = load_yaml(path, match[:yaml])
      body = match[:body].strip
      raise InvalidExercise, "#{path.basename}: the body is empty" if body.empty?

      validate_keys!(path, front_matter)
      validate_slug!(path, front_matter["slug"])

      front_matter.slice(*PERMITTED_KEYS).merge("body_md" => body)
    end

    def load_yaml(path, yaml)
      # Date and Time have to be permitted because published_at is a timestamp;
      # a bare date or datetime in front matter is read as UTC, which is how
      # times are stored everywhere in this app.
      parsed = YAML.safe_load(yaml, permitted_classes: [ Date, Time ], filename: path.to_s)
      unless parsed.is_a?(Hash)
        raise InvalidExercise, "#{path.basename}: front matter is not a set of key/value pairs"
      end

      parsed
    rescue Psych::Exception => error
      raise InvalidExercise, "#{path.basename}: #{error.message}"
    end

    def validate_keys!(path, front_matter)
      missing = REQUIRED_KEYS - front_matter.keys
      if missing.any?
        raise InvalidExercise, "#{path.basename}: missing front matter #{missing.to_sentence}"
      end

      # An unknown key is nearly always a typo, and ignoring it would leave the
      # column it meant to set at its default without saying so.
      unknown = front_matter.keys - PERMITTED_KEYS
      if unknown.any?
        raise InvalidExercise, "#{path.basename}: unknown front matter #{unknown.to_sentence}"
      end
    end

    def validate_slug!(path, slug)
      expected = path.basename(".md").to_s
      return if slug == expected

      raise InvalidExercise,
        "#{path.basename}: front matter says slug #{slug.inspect}, filename says #{expected.inspect}"
    end
end
