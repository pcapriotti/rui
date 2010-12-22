# Copyright (c) 2010 Paolo Capriotti <p.capriotti@gmail.com>
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'test/unit'
require 'rui/factory'

class TestFactory < Test::Unit::TestCase
  def test_simple_factory
    factory = Factory.new { "hello" }
    assert_equal "hello", factory.new
  end

  def test_factory_with_arguments
    factory = Factory.new {|x, y| x + y }
    assert_equal 42, factory.new(40, 2)
  end

  def test_component
    factory = Factory.new(Array) do |n, value|
      Array.new(n) { value }
    end
    assert_equal Array, factory.component
    assert_equal Array, factory.new(10, "hello").class
  end

  def test_rebind
    factory = Factory.new(Array) do |n, value|
      new(n) { value }
    end
    factory = factory.__bind__(factory.component)
    assert_equal Array, factory.component
    assert_equal [:hello, :hello], factory.new(2, :hello)
  end
end
