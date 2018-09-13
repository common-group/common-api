# coding: utf-8
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddressPolicy do
  subject { described_class }
  let(:platform) { create(:platform) }
  let(:user_one) { create(:user, platform: platform) }
  let(:user_two) { create(:user, platform: platform) }
  let!(:another_user) { create(:user) }
  let!(:address) { build(:address, platform: platform) }

  permissions :create? do
    it "denies when user from another platform" do
      expect(subject).to_not permit(another_user, address)
    end

    it "permit when user is from same platform" do
      expect(subject).to permit(user_one, address)
    end

    it "permit when platform_user is from current platform" do
      expect(subject).to permit(platform, address)
    end
  end

  describe 'strong parameters' do
    describe 'permitted_attributes' do
      subject { described_class.new(user_one, address).permitted_attributes }

      it { is_expected.to include(:address_street) }
      it { is_expected.to include(:phone_number) }
    end
  end
end
