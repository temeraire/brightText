require 'test_helper'

class StoryGroupsControllerTest < ActionController::TestCase
  setup do
    @story_group = story_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:story_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create story_group" do
    assert_difference('StoryGroup.count') do
      post :create, :story_group => @story_group.attributes
    end

    assert_redirected_to story_group_path(assigns(:story_group))
  end

  test "should show story_group" do
    get :show, :id => @story_group.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @story_group.to_param
    assert_response :success
  end

  test "should update story_group" do
    put :update, :id => @story_group.to_param, :story_group => @story_group.attributes
    assert_redirected_to story_group_path(assigns(:story_group))
  end

  test "should destroy story_group" do
    assert_difference('StoryGroup.count', -1) do
      delete :destroy, :id => @story_group.to_param
    end

    assert_redirected_to story_groups_path
  end
end
