# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::AddressesController, type: :controller do
  let!(:platform) { create(:platform) }
  let!(:another_platform) { create(:platform) }

  let(:address) { build(:address, platform: platform) }
  let(:user) { create(:user, platform: platform, address: address) }
  let(:another_platform_user) { create(:user, platform: another_platform) }

  let(:current_user) { user }
  let(:token_role) { 'scoped_user' }
  let(:platform_token) { platform.token }
  let(:user_id) { current_user.id }
  let(:policy_model_class) { CommonModels::Address }
  let(:policy_scope_class) { AddressPolicy::Scope }

  before do
    allow(controller).to receive(:decoded_api) do
      { user_id: user_id,
        role: token_role,
        platform_token: platform_token }.stringify_keys
    end
  end

  describe 'POST #create' do

    subject { response }

    context 'with anonymous' do
      include_examples 'with anonymous'
      before do
        post :create, params: { address: address.attributes }
      end

      it { is_expected.to have_http_status('403') }
    end

    context 'with platform_user from current_platform' do
      include_examples 'with platform user from current platform'
      include_examples 'ensure policy scope usage'
      let(:address_params) { address.attributes }

      before do
        post :create, params: { address: address_params }
      end

      it { is_expected.to have_http_status('200') }
      it 'should create a new address' do
        json = JSON.parse(response.body)
        expect(CommonModels::Address.find(json['address_id']).present?).to eq(true)
      end
    end

    context 'with scoped_user not owner of address' do
      include_examples 'ensure policy scope usage'
      let(:not_owner) { create(:user, platform: platform) }
      let(:token_role) { 'scoped_user' }
      let(:user_id) { not_owner.id }
      let(:address) { build(:address, platform: another_platform) }
      let(:address_params) { address.attributes }

      it 'should not allow' do
        expect {
          post :create, params: { address: address_params }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'with scoped_user owner of address' do
      include_examples 'ensure policy scope usage'
      let(:address_params) { { phone_number: '9999999999' } }

      before do
        post :create, params: { address: address_params }
      end

      context 'with missing attributes' do
        it 'should be invalid request and return error validation messages' do
          json = JSON.parse(response.body).deep_symbolize_keys
          expect(response.code).to eq("400")

          expect(json[:country]).to eq(["can't be blank"])
          expect(json[:state]).to eq(["can't be blank"])
        end
      end

      context 'with valid attributes' do
        let(:address_params) { address.attributes }
        it 'should create a new address' do
          json = JSON.parse(response.body)
          expect(response.code).to eq("200")
          expect(CommonModels::Address.find(json['address_id']).present?).to eq(true)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:address) { create(:address, platform: platform) }
    let(:address_params) { { phone_number: '111111', address_street: 'changed street' } }

    subject { response }

    context 'with anonymous' do
      include_examples 'with anonymous'
      before do
        put :update, params: { id: address.id, address: address_params }
      end

      it { is_expected.to have_http_status('403') }
    end

    context 'with platform_user from another platform' do
      include_examples 'with platform user from another platform'

      it do
        expect {
          put :update, params: { id: address.id, address: address_params }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with platform_user from current_platform' do
      include_examples 'with platform user from current platform'
      include_examples 'ensure policy scope usage'

      before do
        put :update, params: {  id: address.id, address: address_params }
      end

      it { is_expected.to have_http_status('200') }

      it 'should updated address' do
        json = JSON.parse(response.body)
        changed = CommonModels::Address.find(json['address_id'])
        expect(changed.address_street).to eq('changed street')
        expect(changed.phone_number).to eq('111111')
      end
    end

    context 'with scoped_user not owner of address' do
      include_examples 'ensure policy scope usage'

      let(:not_owner) { create(:user, platform: platform) }
      let(:token_role) { 'scoped_user' }
      let(:user_id) { not_owner.id }
      let(:address_params) { address.attributes }

      it 'should not allow' do
        expect {
          put :update, params: { id: address.id, address: address_params }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'with scoped_user owner of address' do
      include_examples 'ensure policy scope usage'
      before do
        put :update, params: { id: address.id, address: address_params }
      end

      context 'with missing attributes' do
        let(:address_params) { { state_id: nil } }
        it 'should be invalid request and return error validation messages' do
          json = JSON.parse(response.body).deep_symbolize_keys
          expect(response.code).to eq("400")

          expect(json[:state]).to eq(["can't be blank"])
        end
      end

      context 'with valid attributes' do
        it 'should create a new address' do
          json = JSON.parse(response.body)
          changed = CommonModels::Address.find(json['address_id'])
          expect(changed.address_street).to eq('changed street')
          expect(changed.phone_number).to eq('111111')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:address) { create(:address, platform: platform) }

    subject { response }

    context 'with anonymous' do
      include_examples 'with anonymous'
      before do
        delete :destroy, params: { id: address.id }
      end

      it { is_expected.to have_http_status('403') }
    end

    context 'with platform_user from another platform' do
      include_examples 'with platform user from another platform'

      it do
        expect {
          delete :destroy, params: { id: address.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with platform_user from current_platform' do
      include_examples 'with platform user from current platform'
      include_examples 'ensure policy scope usage'

      before do
        delete :destroy, params: { id: address.id }
      end

      it { is_expected.to have_http_status('200') }

      it 'should delete address' do
        json = JSON.parse(response.body)
        expect {
          CommonModels::Address.find(json['address_id'])
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with scoped_user not owner of address' do
      include_examples 'ensure policy scope usage'
      let(:not_owner) { create(:user, platform: platform) }
      let(:token_role) { 'scoped_user' }
      let(:user_id) { not_owner.id }
      let(:address_params) { address.attributes }

      it 'should not allow' do
        expect {
          delete :destroy, params: { id: address.id }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'with scoped_user owner of address' do
      include_examples 'ensure policy scope usage'
      before do
        delete :destroy, params: { id: address.id }
      end

      it 'should delete address' do
        json = JSON.parse(response.body)
        expect {
          CommonModels::Address.find(json['address_id'])
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end
