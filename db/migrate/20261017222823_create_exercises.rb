class CreateExercises < ActiveRecord::Migration[8.2]
  def change
    create_table :exercises do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :summary, null: false
      t.text :body_md, null: false
      t.string :difficulty, null: false
      t.string :topic, null: false
      t.integer :minutes, null: false

      # Null means never published. A future value means hidden: absent from the
      # library and a 404 on its own page, which is what makes scheduled
      # publishing work (codegym-wwd).
      t.datetime :published_at

      t.timestamps

      # Constraints live in the database as well as the model so a bad row cannot
      # arrive through the seed loader, a console session, or a future importer.
      t.check_constraint "difficulty IN ('easy', 'medium', 'hard')",
        name: "exercises_difficulty_known"
      t.check_constraint "minutes >= 0 AND minutes <= 600",
        name: "exercises_minutes_in_range"
    end

    add_index :exercises, :slug, unique: true

    # The library lists published exercises newest first.
    add_index :exercises, :published_at
  end
end
