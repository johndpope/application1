require 'rails_helper'

RSpec.describe BotServer, type: :model do
  let(:bot_server) {BotServer.new}

  describe '.attributes' do
    %w(name path active_threads_data inactive_threads_data hardware_data hardware_data_updated_at human_emulation).each do |a|
      it(a) { expect(bot_server).to respond_to(a) }
    end
  end
end
