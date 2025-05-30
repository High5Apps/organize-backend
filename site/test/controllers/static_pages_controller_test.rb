require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get about" do
    get about_url
    assert_response :success
  end

  test "should get aeiou_framework" do
    get blog_aeiou_framework_url
    assert_response :success
  end

  test "should get blog" do
    get blog_url
    assert_response :success
  end

  test "should get community_allies" do
    get blog_community_allies_url
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

  test "should get negotiations" do
    get blog_negotiations_url
    assert_response :success
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
  end

  test "should get structure_tests" do
    get blog_structure_tests_url
    assert_response :success
  end

  test "should get terms" do
    get terms_url
    assert_response :success
  end

  test "should get tips_for_organic_leader_identification" do
    get blog_tips_for_organic_leader_identification_url
    assert_response :success
  end

  test "should get tips_for_organizing_conversations" do
    get blog_tips_for_organizing_conversations_url
    assert_response :success
  end

  test "should get tips_for_starting_a_union" do
    get blog_tips_for_starting_a_union_url
    assert_response :success
  end

  test "should get union_busting_defenses" do
    get blog_union_busting_defenses_url
    assert_response :success
  end
end
