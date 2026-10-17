class CreateUsers < ActiveRecord::Migration[8.2]
  def change
    create_table :users do |t|
      # Identity is github_id, not login: a GitHub user can rename themselves and
      # keep the same numeric id. bigint because GitHub ids are numeric and still
      # growing. Name and avatar_url are deliberately absent until a page needs
      # them (codegym-ir5).
      t.bigint :github_id, null: false
      t.string :login, null: false

      t.timestamps
    end

    add_index :users, :github_id, unique: true
  end
end
