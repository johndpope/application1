require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => "192.168.123.11",
  :port => '5432',
  :username => "postgres",
  :password => "changeme",
  :database => "broadcaster",
  :pool=>5,
  :timeout=>5000
)

ActiveRecord::Base.connection.rename_column(:api_operations, :broadcast_stream, :broadcast_stream_id)