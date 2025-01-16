class V1::OfficesController < ApplicationController
  def index
    offices = Office.availability_in authenticated_user.org
    render json: { offices: }
  end
end
