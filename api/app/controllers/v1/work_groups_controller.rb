class V1::WorkGroupsController < ApplicationController
  def index
    render json: { work_groups: }
  end

  private

  def work_groups
    authenticated_user.org.work_groups.joins(:union_cards).group(:id)
      .select :encrypted_department,
        :encrypted_job_title,
        :encrypted_shift,
        :id,
        'COUNT(*) AS member_count'
  end
end
