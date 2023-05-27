require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  setup do
    @connection = connections(:one)
    @sharer = @connection.sharer
    @scanner = @connection.scanner

    @user_without_org = users(:two)
    assert_nil @user_without_org.org

    @user_with_org = users(:one)
    assert_not_nil @user_with_org.org

    @user_with_other_org = users(:five)
    assert_not_nil @user_with_org.org

    assert_not_equal @user_with_org.org, @user_with_other_org.org
  end

  test 'should be valid' do
    assert @connection.valid?
  end

  test 'sharer should be present' do
    @connection.sharer = nil
    assert_not @connection.valid?
  end

  test 'scanner should be present' do
    @connection.scanner = nil
    assert_not @connection.valid?
  end

  test 'should not create duplicate connections' do
    duplicate_connection = @connection.dup
    assert_not duplicate_connection.valid?
  end

  test 'should not create when alreday connected in reverse' do
    reverse_connection = @connection.sharer.scanned_connections.create(
      sharer: @connection.scanner)

    assert_not reverse_connection.valid?

    error_messages = reverse_connection.errors.full_messages
    assert_equal 1, error_messages.count
    assert_equal Connection::ERROR_MESSAGE_ALREADY_CONNECTED,
      error_messages.first
  end

  test 'should not be able to connect to yourself' do
    self_connection = @user_with_org.scanned_connections.create(
      sharer: @user_with_org)
    assert_not self_connection.valid?

    error_messages = self_connection.errors.full_messages
    assert_equal 1, error_messages.count
    assert_equal Connection::ERROR_MESSAGE_SELF_CONNECTION, error_messages.first
  end

  test "sharer's scanners should include scanner" do
    assert_not_nil @sharer.scanners.find_by_id(@scanner.id)
    assert_nil @sharer.scanners.find_by_id(@sharer.id)
  end

  test "scanners's sharers should include sharer" do
    assert_not_nil @scanner.sharers.find_by_id(@sharer.id)
    assert_nil @scanner.sharers.find_by_id(@scanner.id)
  end

  test 'scanned_connections should be correct' do
    scanned_connections = users(:three).scanned_connections
    assert_equal 1, scanned_connections.count
    assert_equal scanned_connections.first, connections(:one)
  end

  test 'shared_connections should be correct' do
    shared_connections = users(:four).shared_connections
    assert_equal 1, shared_connections.count
    assert_equal shared_connections.first, connections(:two)
  end

  test 'directly_connected_to? should be correct' do
    u1 = users(:one)
    u2 = users(:two)
    u3 = users(:three)
    u4 = users(:four)
    assert Connection.directly_connected?(u1, u3)
    assert Connection.directly_connected?(u1, u4)
    assert_not Connection.directly_connected?(u1, u1)
    assert_not Connection.directly_connected?(u1, u2)
    assert_not Connection.directly_connected?(u3, u4)
  end

  test 'between should be correct' do
    u1 = users(:one)
    u2 = users(:two)
    u3 = users(:three)
    u4 = users(:four)
    assert_equal connections(:one), Connection.between(u1, u3)
    assert_equal connections(:one), Connection.between(u3, u1)
    assert_equal connections(:two), Connection.between(u1, u4)
    assert_equal connections(:two), Connection.between(u4, u1)
    assert_nil Connection.between(u1, u1)
    assert_nil Connection.between(u1, u2)
    assert_nil Connection.between(u3, u4)
  end

  test 'scanner org is set from sharer org when nil' do
    assert_nil @user_without_org.org
    @user_without_org.scanned_connections.create!(sharer: @user_with_org)
    assert_equal @user_with_org.org, @user_without_org.reload.org
  end

  test 'scanner recruiter is set to sharer when nil' do
    assert_nil @user_without_org.recruiter
    @user_without_org.scanned_connections.create!(sharer: @user_with_org)
    assert_equal @user_with_org, @user_without_org.reload.recruiter
  end

  test 'cannot create connection to another org' do
    connection = @user_with_org.scanned_connections.create(
      sharer: @user_with_other_org)
    error_messages = connection.errors.full_messages
    assert_equal 1, error_messages.count
    assert_equal Connection::ERROR_MESSAGE_DIFFERENT_ORGS, error_messages.first
  end
end
