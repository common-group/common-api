class AddressPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if is_platform_user?
        scope.where(platform_id: user.id)
      else
        scope.where(
          platform_id: user.platform_id
        )
      end
    end
  end

  def create?
    is_platform_user? || record.platform_id == user.platform_id
  end

  def update?
    is_platform_user? || user.address.try(:id) == record.id
  end

  alias_method :destroy?, :update?

  def permitted_attributes
    %i[
      platform_id country_id state_id external_id address_street
      address_number address_complement address_neighbourhood address_city
      address_zip_code address_state phone_number
    ]
  end
end
