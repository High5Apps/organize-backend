class Api::V1::PermissionsController < ApplicationController
  before_action :authenticate_user, only: [:show_by_scope]
  before_action :check_org_membership, only: [:show_by_scope]
  before_action :check_can_view_permissions, only: [:show_by_scope]
  before_action :check_valid_scope, only: [:show_by_scope]

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

  def check_can_view_permissions
    render_unauthorized unless authenticated_user.can? :view_permissions
  end
end
