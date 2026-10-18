# Exercises are authored as Markdown under db/exercises/ and are the source of
# truth; this table is a projection of them. Running this twice changes nothing
# the second time. See docs/decisions/0002-exercises-as-files.md.
result = ExerciseLoader.load_all
puts "Loaded #{result}."
