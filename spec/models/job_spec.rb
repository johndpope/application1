require 'spec_helper'

describe Job do

  let(:job) { Job.new }

  subject { job }

  it { should respond_to(:run_at) }
end
