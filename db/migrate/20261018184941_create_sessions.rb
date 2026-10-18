class CreateSessions < ActiveRecord::Migration[8.2]
  def change
    create_table :sessions do |t|
      # Sessions live in the database rather than only in a cookie so they can
      # be revoked: deleting the row ends the session on the next request,
      # which a self-contained cookie cannot offer.
      t.references :user, null: false, index: false,
        foreign_key: { on_delete: :cascade }

      # Recorded so a session list can say where a sign-in came from. Nullable
      # because neither is guaranteed to be present on a request.
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    # Sessions are read by user and expired by age, and a user signing out
    # everywhere reads them all. created_at carries the expiry, so it is part of
    # the index rather than an afterthought.
    add_index :sessions, [ :user_id, :created_at ]
  end
end
