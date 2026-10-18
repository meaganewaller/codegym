class AddProfileToUsers < ActiveRecord::Migration[8.2]
  def change
    # Deferred from codegym-g70 until a page needed them. Both are refreshed
    # from GitHub on every sign-in, and both are nullable: a GitHub account can
    # have no display name, and the avatar is presentation only.
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
  end
end
