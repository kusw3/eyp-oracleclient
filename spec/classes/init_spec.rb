require 'spec_helper'
describe 'oracleclient' do

  context 'with defaults for all parameters' do
    it { should contain_class('oracleclient') }
  end
end
