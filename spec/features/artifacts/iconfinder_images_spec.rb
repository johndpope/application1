require 'rails_helper'
require 'features/concerns/artifacts/images_strategy'

RSpec.describe Artifacts::IconfinderImage, type: :feature do
  include_examples 'image artifact features'
end
