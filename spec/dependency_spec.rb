require 'spec_helper'
require 'jpm/dependency'

describe JPM::Dependency do
  describe '.from_hash' do
    subject(:dependency) { described_class.from_hash(data) }

    context 'with real data' do
      let(:data) do
        {"name"=>"ssh-credentials", "optional"=>false, "version"=>"1.5.1"}
      end

      it { is_expected.to be_instance_of described_class }
      it { is_expected.not_to be_optional }
      its(:name) { should eql 'ssh-credentials' }
      its(:min_version) { should eql '1.5.1' }
    end
  end
end
