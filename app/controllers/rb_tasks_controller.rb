include RbCommonHelper

class RbTasksController < RbApplicationController
  unloadable

  def create
    @settings = Backlogs.settings
    @task = nil
    begin
      @task  = RbTask.create_with_relationships(params, User.current.id, @project.id)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    result = @task.errors.size
    status = (result == 0 ? 200 : 400)
    @include_meta = true

    if status == 200 then
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @task})
    end

    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

  def update
    @task = RbTask.find_by_id(params[:id])
    @settings = Backlogs.settings
    result = @task.update_with_relationships(params)
    status = (result ? 200 : 400)
    @include_meta = true

    if status == 200 then
      issue = Issue.find_by_id(params[:id])
      journal = Journal.find_by_journalized_id(params[:id])
      call_hook(:controller_issues_edit_after_save, { :params => params, :issue => issue, :journal => journal})
    end

    @task.story.story_follow_task_state if @task.story

    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

end
