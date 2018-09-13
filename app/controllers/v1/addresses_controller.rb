# frozen_string_literal: true

module V1
  class AddressesController < ApiBaseController
    include Pundit
    after_action :verify_policy_scoped
    before_action :authenticate_user!

    def create
      resource = collection
                  .new(permitted_attributes(resource))

      authorize resource, :create?
      resource.save

      return render json: resource.errors, status: 400 unless resource.valid?
      render json: { address_id: resource.id }
    end

    def update
      resource = collection.find params[:id]
      authorize resource, :update?
      resource.update_attributes(permitted_attributes(resource))

      resource.save

      return render json: resource.errors, status: 400 unless resource.valid?
      render json: { address_id: resource.id }
    end

    def destroy
      resource = collection.find params[:id]
      authorize resource, :destroy?

      return render status: 200, json: { address_id: resource.id, deleted: 'OK' } if resource.destroy
      render status: 400, json: resource.errors
    end

    private

    def policy(record)
      AddressPolicy.new(current_user, record)
    end

    def pundit_params_for(record)
      params.require(:address)
    end

    def collection
      @collection ||= policy_scope(
        CommonModels::Address,
        policy_scope_class: AddressPolicy::Scope
      )
    end
  end
end
