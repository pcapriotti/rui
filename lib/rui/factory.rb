# Copyright (c) 2009 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

class Proc
  #
  # Bind this Proc to an object.
  #
  def bind(object)
    block, time = self, Time.now
    (class << object; self end).class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end

#
# A Factory is a wrapper around a Proc that exposes it through its {Factory#new
# new} method.
#
# Wrapping a Proc in a Factory is useful to have a uniform API across classes
# and custom object-creating lambdas. For instance, if a method create_object
# takes a class as argument, like:
#
#   def create_object(klass)
#     obj = klass.new('foo')
#     # do something with obj
#     obj
#   end
#
# you can pass modified class constructors:
#
#   create_object(Factory.new {|arg| Array.new(4) { arg } })
#
# and have the method behave as if the passed argument were a normal class.
#
class Factory
  #
  # A Factory can specify a <b>component</b>, which is the class used to
  # instantiate the objects created by this Factory.
  #
  # When non-nil, it should satisfy <tt>component == new(*args).class</tt>.
  #
  # @return the component of this Factory
  #
  attr_reader :component

  #
  # Create a factory object.
  #
  # @param component[Class] the factory component
  # @param &blk the wrapped Proc
  #
  def initialize(component = nil, &blk)
    @blk = blk
    @component = component
  end
  
  #
  # Call the wrapped Proc
  #
  def new(*args)
    @blk[*args]
  end
  
  #
  # Rebind this Factory.
  #
  # Binding a Factory to an object causes the wrapped Proc to be executed in
  # the given object's scope.
  #
  # @param object the object to bind this Factory to
  #
  def __bind__(object)
    Factory.new(@component, &@blk.bind(object))
  end
end
