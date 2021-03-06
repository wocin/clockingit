require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  fixtures :customers, :projects

  context "a logged in user" do
    setup do
      #login as admin
      @user = login
      @project = projects(:test_project)
    end

    should "get list page" do
      get :list
      assert_response :success
    end

    should "get new project page" do
      get :new
      assert_response :success
    end

    should "create project and copy project permissions" do
      assert_difference("Project.count", +1) do
        post :create, {:project=>{:name=>"New Project", :create_forum=>"0",
                                  :description=>"Some description",
                                  :customer=>customers(:internal_customer)},
                       :copy_project=>@project.id}
      end
      assert_equal 3, assigns[:project].project_permissions.size
      assert_redirected_to :action => "edit", :id => assigns[:project].id
    end

    should "get edit project page" do
      get :edit, :id => @project.id
      assert_response :success
    end

    should "update project" do
      post :update, {:project=>{:name=>"New Project Name", :description=>"New Project Description",
                     :customer_id=>customers(:internal_customer).id},
                     :id=>@project.id,
                     :customer=>{:name=>customers(:internal_customer).name}}
      assert_equal "New Project Name", assigns[:project].name
      assert_equal "New Project Description", assigns[:project].description
      assert_redirected_to :action=> "list"
    end

    should "complete project" do
      get :complete, {:id => @project.id}
      assert_not_nil @project.reload.completed_at
      assert_redirected_to :controller => 'activities', :action => "list"
    end

    should "revert project" do
      get :revert, {:id => projects(:completed_project).id}
      assert_nil projects(:completed_project).reload.completed_at
      assert_redirected_to :controller => 'activities', :action => "list"
    end

    should "remove project and its worklogs, tasks, pages, milestones, sheets, project permissions" do
      @project.sheets << Sheet.make(:user => @user)
      @project.pages << Page.make(:notable => @project)
      @project.work_logs << WorkLog.make(:user => @user)
     
      assert_difference("Project.count", -1) do
        delete :destroy, :id => @project.id
      end
      assert_equal 0, Page.where(:notable_id => @project.id, :notable_type => "Project").count
      assert_equal 0, Task.where(:project_id => @project.id).count
      assert_equal 0, WorkLog.where(:project_id => @project.id).count
      assert_equal 0, Milestone.where(:project_id => @project.id).count
      assert_equal 0, Sheet.where(:project_id => @project.id).count
      assert_equal 0, ProjectPermission.where(:project_id => @project.id).count
      assert_redirected_to :action=> "list"
    end
    
  end

end
