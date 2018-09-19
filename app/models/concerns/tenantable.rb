module Tenantable
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      belongs_to :client

      default_scope { manageable }
    end
  end

  def manageable?
    client_id == Client.current_id
  end

  def available?
    manageable? || client_id.nil?
  end

  module ClassMethods
    def available
      unscoped.where(client_id: [Client.current_id, nil])
    end

    def manageable
      where(client_id: Client.current_id)
    end
  end
end
