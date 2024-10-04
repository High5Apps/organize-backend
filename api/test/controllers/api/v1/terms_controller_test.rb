require "test_helper"

class Api::V1::TermsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @term = terms :three
    @user = @term.user
    setup_test_key(@user)
    @authorized_headers = authorized_headers @user, Authenticatable::SCOPE_ALL
  end

  test 'should create with valid params' do
    params = destroy_template_term_for_create_params
    assert_difference 'Term.count', 1 do
      post(api_v1_ballot_terms_url(@term.ballot),
        headers: @authorized_headers,
        params:)
      assert_response :created
    end

    assert_pattern { response.parsed_body => id: String, **nil }
  end

  test 'should not create with invalid authorization' do
    params = destroy_template_term_for_create_params
    assert_no_difference 'Term.count' do
      post(api_v1_ballot_terms_url(@term.ballot),
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params:)
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    params = destroy_template_term_for_create_params.merge term: {}
    assert_no_difference 'Term.count' do
      post(api_v1_ballot_terms_url(@term.ballot),
        headers: @authorized_headers,
        params:)
    end

    assert_response :unprocessable_entity
  end

  private

  def destroy_template_term_for_create_params
    # Destroy the existing term to prevent triggering duplicate validation
    # errors
    @term.destroy!
    { term: @term.as_json }
  end
end
