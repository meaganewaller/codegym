class CreateAttempts < ActiveRecord::Migration[8.2]
  def change
    create_table :attempts do |t|
      # Deleting a user takes their attempts with them; deleting an exercise that
      # people have already attempted is refused by the database, because those
      # attempts are the user's own history and should not vanish with content.
      # index: false because the composite (user_id, created_at) index below
      # already serves user_id-only lookups as its left prefix. The exercise
      # side keeps its own index for exercise-scoped queries.
      t.references :user, null: false, index: false,
        foreign_key: { on_delete: :cascade }
      t.references :exercise, null: false, foreign_key: true

      t.string :outcome, null: false
      t.integer :minutes, null: false

      # Free text, and optional: a sitting can be logged before you have words
      # for what you learned.
      t.text :plan
      t.text :stuck_on
      t.text :learned

      t.timestamps

      t.check_constraint "outcome IN ('solved', 'partial', 'stuck')",
        name: "attempts_outcome_known"
      t.check_constraint "minutes >= 0 AND minutes <= 600",
        name: "attempts_minutes_in_range"
    end

    # The progress page reads a user's attempts in time order (totals, streaks).
    add_index :attempts, [ :user_id, :created_at ]

    # The library shows solved/tried status per exercise for the current user.
    # Not unique: attempts are append-only, so a retry adds a row.
    add_index :attempts, [ :user_id, :exercise_id ]
  end
end
