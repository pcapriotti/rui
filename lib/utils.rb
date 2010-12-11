# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

class Object
  def tap
    yield self
    self
  end
  
  #
  # Change the value of a propery using a block.
  # Useful for properties that return by value.
  #
  # For example:
  # painter.alter(:pen) do |pen|
  #   pen.width = 3
  # end
  #
  def alter(property)
    value = send(property)
    yield value
    send("#{property}=", value)
  end

  def metaclass
    class << self
      self
    end
  end
  
  def metaclass_eval(&blk)
    metaclass.instance_eval(&blk)
  end
  
  def map
    yield self unless nil?
  end
end


module Enumerable
  def detect_index
    i = 0
    each do |item|
      return i if yield item
      i += 1
    end
    
    nil
  end
end

class Hash
  def maph
    { }.tap do |result|
      each do |key, value|
        key, value = yield key, value
        result[key] = value
      end
    end
  end
end

class String
  def underscore
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         downcase
  end
  
  def camelize
    gsub(/_(.)/) {|m| $1.upcase }
  end
end
