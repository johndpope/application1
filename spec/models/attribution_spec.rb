require 'rails_helper'

RSpec.describe Attribution, type: :model do
  describe '.attributes' do
    let(:attribution) { Attribution.new }

    %w(component_id component_type component resource_id resource_type resource).each do |field|
      it(field) { expect(attribution).to respond_to(field) }
    end
  end
end
