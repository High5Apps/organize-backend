require "test_helper"

class BallotTest < ActiveSupport::TestCase
  setup do
    @ballot = ballots(:one)
  end

  test 'should be valid' do
    assert @ballot.valid?
  end

  test 'category should be present' do
    @ballot.category = nil
    assert @ballot.invalid?
  end

  test 'encrypted_question should be present' do
    @ballot.encrypted_question = nil
    assert @ballot.invalid?
  end

  test 'encrypted_question error messages should not include "Encrypted"' do
    @ballot.encrypted_question = nil
    @ballot.valid?
    assert_not @ballot.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_question should be no longer than MAX_QUESTION_LENGTH' do
    @ballot.encrypted_question.ciphertext = \
      Base64.strict_encode64('a' * Ballot::MAX_QUESTION_LENGTH)
    assert @ballot.valid?

    @ballot.encrypted_question.ciphertext = \
      Base64.strict_encode64('a' * (1 + Ballot::MAX_QUESTION_LENGTH))
    assert @ballot.invalid?
  end

  test 'user should be present' do
    @ballot.user = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be present' do
    @ballot.voting_ends_at = nil
    assert @ballot.invalid?
  end

  test 'voting_ends_at should be in the future' do
    @ballot.voting_ends_at = Time.now
    assert @ballot.invalid?
  end

  test 'active_at should include ballots where voting_ends_at is in the future' do
    b1, b2, b3 = create_ballots_with_voting_ends_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.active_at(b2.voting_ends_at)
    assert_not query.exists?(id: [b1, b2])
    assert query.exists?(id: b3)
  end

  test 'created_before should include ballots where created_at is in the past' do
    b1, b2, b3 = create_ballots_with_created_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.created_before(b2.created_at)
    assert query.exists?(id: b1)
    assert_not query.exists?(id: [b2, b3])
  end

  test 'inactive_at should include ballots where voting_ends_at is past or now' do
    b1, b2, b3 = create_ballots_with_voting_ends_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Ballot.inactive_at(b2.voting_ends_at)
    assert query.exists?(id: [b1, b2])
    assert_not query.exists?(id: b3)
  end

  test 'results should be ordered by most votes first' do
    vote_counts = @ballot.results.map { |r| r[:vote_count] }
    assert_not_equal 0, vote_counts.length
    assert vote_counts.all? { |vc| vc != 0 }
    assert_equal vote_counts.uniq, vote_counts

    # Reverse is needed because sort is an ascending sort
    assert_equal vote_counts.sort.reverse, vote_counts
  end

  test 'results should order tied vote counts by descending candidate_id' do
    tied_results = ballots(:two).results
    vote_counts = tied_results.map { |r| r[:vote_count] }
    assert_equal 1, vote_counts.uniq.length

    candidate_ids = tied_results.map { |r| r[:candidate_id] }

    # Reverse is needed because sort is an ascending sort
    assert_equal candidate_ids.sort.reverse, candidate_ids
  end

  test 'results should only include a single vote per voter' do
    voters_count = @ballot.votes.joins(:user).group(:user_id).count.length
    vote_count = @ballot.votes.count
    assert_operator vote_count, :>, voters_count

    total_result_vote_count = @ballot.results.map { |r| r[:vote_count] }.sum
    assert_equal voters_count, total_result_vote_count
  end

  test "results should only include each voter's most recent vote" do
    assert_equal 1, @ballot.max_candidate_ids_per_vote
    initial_results = @ballot.results
    initial_results_map = initial_results.index_by { |r| r[:candidate_id] }

    most_recent_vote = @ballot.votes.order(created_at: :desc).first
    most_recent_vote_candidate_id = most_recent_vote.candidate_ids.first
    other_candidate = @ballot.candidates
      .where.not(id: most_recent_vote_candidate_id).first
    assert_not_nil other_candidate
    assert_not_equal most_recent_vote_candidate_id, other_candidate

    older_vote = most_recent_vote.dup
    older_vote.candidate_ids = [other_candidate.id]
    older_vote.created_at = most_recent_vote.created_at - 1.second
    older_vote.save!
    assert_equal initial_results, @ballot.results

    newer_vote = older_vote.dup
    newer_vote.created_at = most_recent_vote.created_at + 1.second
    newer_vote.save!
    assert_not_equal initial_results, @ballot.results

    final_results_map = @ballot.results.index_by { |r| r[:candidate_id] }
    assert_equal 1 + initial_results_map[other_candidate.id][:vote_count],
      final_results_map[other_candidate.id][:vote_count]
    assert_equal initial_results_map[most_recent_vote_candidate_id][:vote_count],
      1 + final_results_map[most_recent_vote_candidate_id][:vote_count]
  end

  test 'results should include info for all candidates, not just vote receivers' do
    ballot_with_fewer_votes_than_candidates = ballots(:three)
    vote_count = ballot_with_fewer_votes_than_candidates.votes.count
    candidate_count = ballot_with_fewer_votes_than_candidates.candidates.count
    assert_operator vote_count, :<, candidate_count

    results = ballots(:three).results
    assert_equal candidate_count, results.length
  end

  private

  def create_ballots_with_voting_ends_at(voting_ends_ats)
    voting_ends_ats.map do |voting_ends_at|
      ballot = @ballot.dup
      ballot.update! voting_ends_at: voting_ends_at
      ballot
    end
  end

  def create_ballots_with_created_at(created_ats)
    created_ats.map do |created_at|
      ballot = @ballot.dup
      ballot.update! created_at: created_at
      ballot
    end
  end
end
