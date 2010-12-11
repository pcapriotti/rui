# Copyright (c) 2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'test/unit'
require 'descriptor'

class TestDescriptor < Test::Unit::TestCase
  def test_add_child
    parent = Descriptor.new(:parent)
    child = Descriptor.new(:child)
    parent.add_child(child)
    
    assert_equal 1, parent.children.size
    assert_equal :child, parent.children.first.tag
  end
  
  def test_merge_child_with_no_merge_points
    parent = Descriptor.new(:parent)
    children = (0...5).map do |i|
      child = Descriptor.new("child#{i}".to_sym)
      parent.add_child(child)
    end
    extra_child = Descriptor.new(:extra)
    
    parent.merge_child(extra_child)

    assert_equal 6, parent.children.size
    assert_equal :extra, parent.children.last.tag
  end

  def test_merge_child_with_merge_point
    parent = Descriptor.new(:parent)
    parent.add_merge_point(3)

    (0...5).each do |i|
      child = Descriptor.new("child#{i}".to_sym)
      parent.add_child(child)
    end
    extra_child = Descriptor.new(:extra)
    
    parent.merge_child(extra_child)

    assert_equal 6, parent.children.size
    assert_equal :extra, parent.children[3].tag
  end

  def test_merge_child_with_capped_merge_point
    parent = Descriptor.new(:parent)
    parent.add_merge_point(3, 2)

    (0...5).each do |i|
      child = Descriptor.new("child#{i}".to_sym)
      parent.add_child(child)
    end
    (0...3).each do |i|
      child = Descriptor.new("extra#{i}".to_sym)
      parent.merge_child(child)
    end

    assert_equal 8, parent.children.size
    assert_equal :extra0, parent.children[3].tag
    assert_equal :extra1, parent.children[4].tag
    assert_equal :extra2, parent.children[7].tag
  end

  def test_simple_to_sexp
    desc = Descriptor.new("hello", :foo => 42)
    assert_equal "(hello {:foo=>42})", desc.to_sexp
  end

  def test_hierarchical_to_sexp
    parent = Descriptor.new("parent", :foo => 42)
    child = Descriptor.new("child")
    parent.add_child(child)

    assert_equal("(parent {:foo=>42} (child {}))", parent.to_sexp)
  end

  def test_builder
    desc = Descriptor.build(:gui) do
      menu_bar do
        menu(:file) do
          action :new
          action :open
          separator
          action :quit
        end
      end
    end
    
    sexp = '(gui {} ' +
              '(menu_bar {} ' +
                '(menu {:name=>:file} ' +
                  '(action {:name=>:new}) ' +
                  '(action {:name=>:open}) ' +
                  '(separator {}) ' +
                  '(action {:name=>:quit}))))'
    assert_equal sexp, desc.to_sexp
  end
  
  def test_merge_equal
    desc = Descriptor.build(:gui)
    desc2 = Descriptor.build(:gui)
    
    desc.merge!(desc2)
    sexp = '(gui {})'
    assert_equal sexp, desc.to_sexp
  end
  
  def test_merge_children
    desc = Descriptor.build(:gui) do |g|
      g.item :a
      g.item :b
    end
    
    desc2 = Descriptor.build(:gui) do |g|
      g.item :c
      g.item :d
    end
    
    desc.merge!(desc2)
    sexp = '(gui {} ' +
              '(item {:name=>:a}) ' +
              '(item {:name=>:b}) ' +
              '(item {:name=>:c}) ' +
              '(item {:name=>:d}))'
    assert_equal sexp, desc.to_sexp
  end
  
  def test_merge_recursive
    desc = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.item :a
        mb.item :b
      end
    end
    
    desc2 = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.item :c
        mb.item :d
      end
    end
    
    desc.merge!(desc2)
    sexp = '(gui {} ' +
              '(menu_bar {} ' + 
                '(item {:name=>:a}) ' +
                '(item {:name=>:b}) ' +
                '(item {:name=>:c}) ' +
                '(item {:name=>:d})))'
    assert_equal sexp, desc.to_sexp
  end
  
  def test_simple_merge
    desc = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.menu(:file) do |m|
          m.action :new
          m.action :open
          m.separator
          m.action :quit
        end
      end
    end

    desc2 = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.menu(:file) do |m|
          m.action :save
        end
        mb.menu(:edit) do |m|
          m.action :undo
        end
      end
      g.tool_bar(:main_tool_bar)
    end

    desc.merge!(desc2)
    sexp = '(gui {} ' +
              '(menu_bar {} ' +
                '(menu {:name=>:file} ' +
                  '(action {:name=>:new}) ' +
                  '(action {:name=>:open}) ' +
                  '(separator {}) ' +
                  '(action {:name=>:quit}) ' +
                  '(action {:name=>:save})) ' +
                '(menu {:name=>:edit} ' +
                  '(action {:name=>:undo}))) ' +
              '(tool_bar {:name=>:main_tool_bar}))'
    
    assert_equal sexp, desc.to_sexp
  end
  
  def test_merge_partial
    desc = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.menu(:file) do |m|
          m.action :open
        end
        mb.menu(:edit) do |m|
          m.action :undo
        end
      end
    end
    
    desc2 = Descriptor.build(:gui) do |g|
      g.menu_bar do |mb|
        mb.menu(:edit) do |m|
          m.action :redo
        end
        mb.menu(:game) do |m|
          m.action :forward
          m.action :back
        end
      end
    end
    
    desc.merge!(desc2)
    sexp = '(gui {} ' +
              '(menu_bar {} ' +
                '(menu {:name=>:file} ' +
                  '(action {:name=>:open})) ' +
                '(menu {:name=>:edit} ' +
                  '(action {:name=>:undo}) ' +
                  '(action {:name=>:redo})) ' +
                '(menu {:name=>:game} ' +
                  '(action {:name=>:forward}) ' +
                  '(action {:name=>:back}))))'
    assert_equal sexp, desc.to_sexp
  end
end

