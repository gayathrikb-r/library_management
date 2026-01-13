class CreateDoorkeeperTables < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_applications do |t|
      t.string  :name,    null: false
      t.string  :uid,     null: false
      t.string  :secret,  null: false
      t.text    :redirect_uri
      t.string  :scopes,       null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    add_index :oauth_applications, :uid, unique: true

    create_table :oauth_access_grants do |t|
      # Polymorphic resource owner
      t.bigint   :resource_owner_id, null: false
      t.string   :resource_owner_type, null: false
      
      t.references :application, null: false
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
      t.string   :scopes,            null: false, default: ''
    end

    add_index :oauth_access_grants, :token, unique: true
    add_index :oauth_access_grants, [:resource_owner_id, :resource_owner_type], name: 'index_oauth_access_grants_on_resource_owner'
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id

    create_table :oauth_access_tokens do |t|
      # Polymorphic resource owner
      t.bigint   :resource_owner_id
      t.string   :resource_owner_type
      
      t.references :application
      t.string   :token, null: false
      t.string   :refresh_token
      t.integer  :expires_in
      t.datetime :revoked_at
      t.datetime :created_at, null: false
      t.string   :scopes
      t.string   :previous_refresh_token, null: false, default: ""
    end

    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
    add_index :oauth_access_tokens, [:resource_owner_id, :resource_owner_type], name: 'index_oauth_access_tokens_on_resource_owner'
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
  end
end  