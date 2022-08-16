require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  setup do
    @connection = connections(:one)
    @sharer = @connection.sharer
    @scanner = @connection.scanner
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

  test 'should not be able to connect to a user more than once' do
    duplicate_connection = @connection.dup
    assert_not duplicate_connection.valid?
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
end
