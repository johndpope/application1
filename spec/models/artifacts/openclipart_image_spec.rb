require 'rails_helper'
require 'models/concerns/artifacts/image_strategy'

RSpec.describe Artifacts::OpenclipartImage, type: :model do
  it_behaves_like 'image artifact strategy'
end
