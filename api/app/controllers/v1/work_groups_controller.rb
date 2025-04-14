class V1::WorkGroupsController < ApplicationController
  PERMITTED_PARAMS = [
    :encrypted_department, # Allow nil to reset
    EncryptedMessage.permitted_params(:department),
    EncryptedMessage.permitted_params(:job_title),
    EncryptedMessage.permitted_params(:shift),
  ]

  before_action :check_can_edit_work_groups, only: [:update]

  def index
    render json: { work_groups: }
  end

  def update
    work_group = authenticated_user.org.work_groups.find params[:id]
    if work_group.update update_params
      head :ok
    else
      render_error :unprocessable_entity, work_group.errors.full_messages
    end
  end

  private

  def update_params
    params.require(:work_group).permit PERMITTED_PARAMS
  end

  def work_groups
    authenticated_user.org.work_groups.joins(:union_cards).group(:id)
      .select :encrypted_department,
        :encrypted_job_title,
        :encrypted_shift,
        :id,
        'COUNT(*) AS member_count'
  end
end
