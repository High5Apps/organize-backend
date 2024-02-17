class Api::V1::OfficesController < ApplicationController
  before_action :authenticate_user, only: [:index]
  before_action :check_org_membership, only: [:index]

  def index
    offices = Office.availability_in @org
    render json: { offices: }
  end
end
