class Api::V1::OfficesController < ApplicationController
  before_action :authenticate_user, only: [:index]
  before_action :check_org_membership, only: [:index]

  def index
    # Ignore founder because it's not an electable position
    office_types = Office::TYPE_STRINGS - ['founder']
    filled_offices = Term.joins(:user).where(user: { org: @org })
      .pluck(:office).to_set
    offices = office_types.map do |type|
      open = !filled_offices.include?(type)
      { type:, open: }
    end

    render json: { offices: }
  end
end
