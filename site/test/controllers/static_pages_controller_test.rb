require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get about" do
    get about_url
    assert_response :success
  end

  test "should get blog" do
    get blog_url
    assert_response :success
  end

  test "should get frequently_asked_questions" do
    get faq_url
    assert_response :success
  end

  test "should get home" do
    get root_url
    assert_response :success
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
  end

  test "should get terms" do
    get terms_url
    assert_response :success
  end

  test "should get tips_for_starting_a_union" do
    get blog_tips_for_starting_a_union_url
    assert_response :success
  end
end
