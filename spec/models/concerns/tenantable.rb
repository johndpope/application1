require 'rails_helper'

shared_examples_for 'tenantable' do
  let(:client)               { FactoryGirl.create(:client) }
  let(:another_client)       { FactoryGirl.create(:client) }
  let(:model)                { described_class.to_s.parameterize.underscore.to_sym }
  let!(:clients_item)         { FactoryGirl.create(model, client_id: client.id) }
  let!(:another_clients_item) { FactoryGirl.create(model, client_id: another_client.id) }
  let!(:clientless_item)      { FactoryGirl.create(model, client_id: nil) }

  before { Client.current_id = client.id }
  after { Client.current_id = nil }

  describe '.manageable' do

    def expectation(scope)
      ids = scope.pluck('id')
      expect(ids).to include(clients_item.id)
      expect(ids).to_not include(another_clients_item.id)
      expect(ids).to_not include(clientless_item.id)
    end

    it 'includes only the records associated with the current client' do
      scope = described_class.manageable
      expectation scope
    end

    it 'is the default scope' do
      scope = described_class.all
      expectation scope
    end
  end

  describe '.available' do
    it 'includes client\'s records along with the clientless ones' do
      ids = described_class.available.pluck('id')
      expect(ids).to include(clients_item.id)
      expect(ids).to include(clientless_item.id)
      expect(ids).to_not include(another_clients_item.id)
    end
  end

  describe '#manageable?' do
    it 'checks whether an instance belongs to the current client' do
      expect(clients_item).to be_manageable
      expect(another_clients_item).to_not be_manageable
      expect(clientless_item).to_not be_manageable
    end
  end

  describe '#available?' do
    it 'checks whether an instance belongs to the current client or is clientless' do
      expect(clients_item).to be_available
      expect(another_clients_item).to_not be_available
      expect(clientless_item).to be_available
    end
  end
end
