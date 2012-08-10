require 'test_helper'

class AppSubmissionsControllerTest < ActionController::TestCase
  setup do
    @app_submission = app_submissions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:app_submissions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create app_submission" do
    assert_difference('AppSubmission.count') do
      post :create, :app_submission => @app_submission.attributes
    end

    assert_redirected_to app_submission_path(assigns(:app_submission))
  end

  test "should show app_submission" do
    get :show, :id => @app_submission.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @app_submission.to_param
    assert_response :success
  end

  test "should update app_submission" do
    put :update, :id => @app_submission.to_param, :app_submission => @app_submission.attributes
    assert_redirected_to app_submission_path(assigns(:app_submission))
  end

  test "should destroy app_submission" do
    assert_difference('AppSubmission.count', -1) do
      delete :destroy, :id => @app_submission.to_param
    end

    assert_redirected_to app_submissions_path
  end
end
