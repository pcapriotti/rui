# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

class Object
  def metaclass
    class << self
      self
    end
  end

  def metaclass_eval(&blk)
    metaclass.instance_eval(&blk)
  end
end

class String
  #
  # Convert from camel case to underscore_separated.
  #
  # Examples:
  # connectToServer => connect_to_server
  # POP3ConnectionManager => pop3_connection_manager
  #
  def underscore
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         downcase
  end
  
  #
  # Convert from underscore-separated to camel case.
  #
  # Example: connect_to_server => connectToServer
  #
  def camelize
    gsub(/_(.)/) {|m| $1.upcase }
  end
end
