class Api::V1::PermissionsController < ApplicationController
  PERMITTED_PARAMS = [
    offices: [],
  ]

  before_action :authenticate_user, only: [:create_by_scope, :show_by_scope]
  before_action :check_org_membership, only: [:create_by_scope, :show_by_scope]
  before_action :check_can_edit_permissions,
    only: [:create_by_scope, :show_by_scope]
  before_action :check_valid_scope, only: [:create_by_scope, :show_by_scope]

  def create_by_scope
    permission = @org.permissions.create_with(data: create_params)
      .find_or_create_by(scope: params[:scope])

    # update will no-op if permission was just created or data was unchanged
    if permission.update(data: create_params)
      head :created
    else
      render_error :unprocessable_entity, permission.errors.full_messages
    end
  end

  def show_by_scope
    render json: { permission: @permission_data }
  end

  private

  def check_valid_scope
    @permission_data = Permission.who_can params[:scope], @org
    unless @permission_data
      render_error :not_found, ['Permission not found']
    end
  end

  def create_params
    params.require(:permission).permit(PERMITTED_PARAMS)
  end
end
