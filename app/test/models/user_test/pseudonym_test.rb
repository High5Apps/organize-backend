require "test_helper"

class PseudonymTest < ActiveSupport::TestCase
  SEED = 12345
  TEST_ADJECTIVES = [
    'Adorable',
    'Adventurous',
    'Agreeable',
  ]
  TEST_ANIMALS = [
    'Alpaca',
    'Ant',
    'Antelope',
  ]
  TEST_COMBINATION_COUNT = TEST_ADJECTIVES.length * TEST_ANIMALS.length

  setup do
    @real_pseudonym = User::Pseudonym.new(SEED)
    @create_test_pseudonym = ->(seed) do
      User::Pseudonym.new(
        seed,
        adjectives: TEST_ADJECTIVES,
        animals: TEST_ANIMALS)
    end
    @test_pseudonym = @create_test_pseudonym.call(SEED)
  end

  test 'default animals list should contain 100 unique entries' do
    assert_equal 100, @real_pseudonym.animals.length
  end

  test 'default adjectives list should contain 100 unique entries' do
    assert_equal 100, @real_pseudonym.adjectives.length
  end

  test 'should contain all combinations' do
    assert_equal TEST_COMBINATION_COUNT, @test_pseudonym.to_a.length
  end

  test 'should contain no duplicates' do
    assert_equal TEST_COMBINATION_COUNT, @test_pseudonym.to_a.uniq.length
  end

  test 'should be stable when given the same seed' do
    pseudonym_1 = @create_test_pseudonym.call(SEED)
    pseudonym_2 = @create_test_pseudonym.call(SEED)
    assert_equal pseudonym_1.to_a, pseudonym_2.to_a
  end

  test 'should not return the same list for different seeds' do
    pseudonym_1 = @create_test_pseudonym.call(1)
    pseudonym_2 = @create_test_pseudonym.call(2)
    assert_not_equal pseudonym_1.to_a, pseudonym_2.to_a
  end

  test 'should format as "Adjective Animal"' do
    pseudonym = @test_pseudonym.at(0)
    adjective, animal = pseudonym.split ' '
    assert TEST_ADJECTIVES.include?(adjective)
    assert TEST_ANIMALS.include?(animal)
  end
end
