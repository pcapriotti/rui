# Copyright (c) 2009 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

#
# A <b>descriptor</b> is a rose tree with arbitrary properties at each node, used to
# define GUIs declaratively.
#
# Descriptors can be created using a DSL. For example:
#
#   ex1 = Descriptor.build(:root, :name => 'parent') do
#     child :name => 'foo'
#     child :name => 'bar'
#     merge_point
#     child :name => 'hello' do
#       grandchild :name => 'world'
#     end
#   end
#
# creates a tree which has a node with no name and three children with names
# 'foo', 'bar', and 'hello', and hello having a child of its own, called
# 'world'. Note that <b>descriptor tags</b> (<tt>:root</tt>, <tt>:child</tt> and
# <tt>:grandchild</tt> in the example) are completely arbitrary, but they play
# a special role when merging, together with the <tt>:name</tt> property.
#
# <b>Merging</b> consists of taking two descriptor trees, and matching their roots by
# tag and name. If they match, their children are recursively matched and
# merged, or simply concatenated when no match is found.
#
# For example, if <tt>ex1</tt> above is merged with the following descriptor:
#
#   ex2 = Descriptor.build(:root, :name => 'parent') do
#     child :name => 'foo2'
#     child :name => 'hello' do
#       grandchild :name => 'world2'
#     end
#   end
#
# the resulting descriptor would be equivalent to the one created by:
#
#   ex1_merged_with_ex2 = Descriptor.build(:root, :name => 'parent') do
#     child :name => 'foo'
#     child :name => 'bar'
#     child :name => 'foo2'
#     child :name => 'hello' do
#       grandchild :name => 'world'
#       grandchild :name => 'world2'
#     end
#   end
#
# As can be seen in the example, <b>merge points</b> can be used to specify exactly
# where children of merged descriptors should be inserted.
#
# Merge points can optionally have a <tt>count</tt>, which specifies the number
# of children to be inserted on that particular point. When the count is
# satisfied, additional children are added at the following merge point, or, if
# no more merge points exist, at the bottom.
#
class Descriptor
  attr_reader :tag # @return [Symbol] the descriptor tag
  attr_reader :opts # @return [Hash] properties for this descriptor
  attr_reader :children # @return [Array] children of this descriptor

  #
  # Create a descriptor using the DSL.
  # @param tag [Symbol] descriptor tag
  # @param opts [Hash] arbitrary hash of properties
  # @return [Descriptor]
  #
  def self.build(tag, opts = { }, &blk)
    root = new(tag, opts)
    builder = Builder.new(root)
    builder.instance_eval(&blk) if block_given?
    root
  end
  
  #
  # Create a descriptor with no children.
  # @param tag [Symbol] descriptor tag
  # @param opts [Hash] arbitrary hash of properties
  #
  def initialize(tag, opts = { })
    @tag = tag
    @opts = opts
    @children = []
  end
  
  #
  # Add a child to this descriptor.
  #
  def add_child(desc)
    @children << desc
  end
  
  #
  # Add a child to this descriptor, taking merge points into account.
  #
  def merge_child(desc)
    mp = @opts[:merge_points].first if @opts[:merge_points]
    if mp
      @children.insert(mp.position, desc)
      @opts[:merge_points].step!
    else
      add_child(desc)
    end
  end

  #
  # Add a merge point to this descriptor. Newly added merge points will not
  # affect existing children, even if they were added with <tt>merge_child</tt>
  # @param position merge point position
  # @param count maximum number of children that can be merged at this point.
  #   If negative, no limit on the number of mergeable children is set.
  #
  def add_merge_point(position, count = -1)
    mp = MergePoint.new(position, count)
    @opts[:merge_points] ||= MergePoint::List.new
    @opts[:merge_points].add(mp)
    mp
  end
  
  #
  # Convert this descriptor to a human readable sexp representation. Descriptor
  # properties are printed as ruby hashes.
  #
  def to_sexp
    "(#{@tag} #{@opts.inspect}#{@children.map{|c| ' ' + c.to_sexp}.join})"
  end
  
  #
  # Destructively merge this descriptor with another.
  #
  # Descriptors are merged if they match by tag and name, or if this descriptor
  # has tag <tt>:group</tt> and the other one has a property <tt>:group</tt>
  # set to the name of this descriptor.
  #
  # @param other the descriptor to be merged
  # @return [Boolean] whether the merge was successful
  #
  def merge!(other)
    if tag == other.tag and
        opts[:name] == other.opts[:name]
      # if roots match
      other.children.each do |child2|
        # merge each of the children of the second descriptor
        merged = false
        children.each do |child|
          # try to match with any of the children of the first descriptor
          if child.merge!(child2)
            merged = true
            break
          end
        end
        # if no match is found, just add it as a child of the root
        merge_child(child2.dup) unless merged
      end
      true
    elsif tag == :group and other.opts[:group] == opts[:name]
      # if the root is the group of the second descriptor, add it as a child
      merge_child(other)
    else
      false
    end
  end
  
  class MergePoint
    attr_accessor :position, :count
    
    class List
      def initialize
        @mps = []
      end
      
      def first
        @mps.first
      end
      
      def add(mp)
        @mps << mp
      end
      
      def step!
        raise "Stepping invalid merge point list" if @mps.empty?
        @mps.each do |mp|
          mp.position += 1
        end
        @mps.first.count -= 1
        clean!
      end
      
      private
      
      def clean!
        @mps.delete_if {|mp| not mp.valid? }
      end
    end
    
    def initialize(position, count = -1)
      @position = position
      @count = count
      raise "Creating invalid merge point" if @count == 0
    end
    
    def valid?
      @count != 0
    end
  end
  
  class Builder
    attr_reader :__desc__
    private :__desc__
    
    def initialize(desc)
      @__desc__ = desc
    end
    
    def method_missing(name, *args, &blk)
      opts = if args.empty?
        { }
      elsif args.size == 1
        if args.first.is_a? Hash
          args.first
        else
          { :name => args.first }
        end
      else
        args[-1].merge(:name => args.first)
      end
      child = Descriptor.new(name, opts)
      self.class.new(child).instance_eval(&blk) if block_given?
      __desc__.add_child(child)
    end
    
    def merge_point(count = -1)
      @__desc__.add_merge_point(@__desc__.children.size, count)
    end
  end
end
