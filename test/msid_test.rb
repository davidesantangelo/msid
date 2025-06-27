# frozen_string_literal: true

require 'test_helper'
require 'digest'

class MsidTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Msid::VERSION
  end

  def test_generate_returns_a_sha256_string
    # This test runs on the actual machine, so we can't assert a fixed value,
    # but we can check the format.
    id = Msid.generate
    assert_kind_of String, id
    assert_equal 64, id.length
    assert_match(/^[a-f0-9]{64}$/, id)
  end

  def test_generate_is_consistent
    id1 = Msid.generate
    id2 = Msid.generate
    assert_equal id1, id2
  end

  def test_generate_with_salt_is_different
    id_no_salt = Msid.generate
    id_with_salt = Msid.generate(salt: 'my-secret')
    refute_equal id_no_salt, id_with_salt
  end

  def test_generate_with_different_salts_are_different
    id1 = Msid.generate(salt: 'salt1')
    id2 = Msid.generate(salt: 'salt2')
    refute_equal id1, id2
  end

  def test_generate_with_same_salt_is_consistent
    id1 = Msid.generate(salt: 'same-salt')
    id2 = Msid.generate(salt: 'same-salt')
    assert_equal id1, id2
  end

  def test_raises_error_when_no_components_found
    Msid::Generator.stub :gather_components, [] do
      assert_raises Msid::Error do
        Msid.generate
      end
    end
  end

  def test_hashing_logic
    components = %w[comp1 comp2 comp3]
    expected_data = components.join(':')
    expected_hash = Digest::SHA256.hexdigest(expected_data)

    Msid::Generator.stub :gather_components, components do
      assert_equal expected_hash, Msid.generate
    end
  end

  def test_hashing_logic_with_salt
    components = %w[comp1 comp2]
    salt = 'my-salt'
    expected_data = (components + [salt.to_s]).join(':')
    expected_hash = Digest::SHA256.hexdigest(expected_data)

    Msid::Generator.stub :gather_components, components do
      assert_equal expected_hash, Msid.generate(salt: salt)
    end
  end
end
