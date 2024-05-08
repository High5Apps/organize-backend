class Api::V1::OfficesController < ApplicationController
  before_action :authenticate_user, only: [:index]

  def index
    offices = Office.availability_in authenticated_user.org
    render json: { offices: }
  end
end
