require 'test_helper'

class DomainStylesControllerTest < ActionController::TestCase
  setup do
    @domain_style = domain_styles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:domain_styles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create domain_style" do
    assert_difference('DomainStyle.count') do
      post :create, :domain_style => @domain_style.attributes
    end

    assert_redirected_to domain_style_path(assigns(:domain_style))
  end

  test "should show domain_style" do
    get :show, :id => @domain_style.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @domain_style.to_param
    assert_response :success
  end

  test "should update domain_style" do
    put :update, :id => @domain_style.to_param, :domain_style => @domain_style.attributes
    assert_redirected_to domain_style_path(assigns(:domain_style))
  end

  test "should destroy domain_style" do
    assert_difference('DomainStyle.count', -1) do
      delete :destroy, :id => @domain_style.to_param
    end

    assert_redirected_to domain_styles_path
  end
end
