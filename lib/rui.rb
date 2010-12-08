# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'rubygems' rescue nil
require 'observer_utils'
require 'utils'
require 'builder'

case ($toolkit || :kde)
when :qt
  require 'Qt4'
  KDE = Qt
  require 'toolkits/compat/qtkde'
when :kde
  require 'korundum4'
  require 'toolkits/kde'
end

module KDE
  def self.autogui(name, opts = { }, &blk)
    Descriptor.new(:gui, opts.merge(:gui_name => name)).tap do |desc|
      blk[Descriptor::Builder.new(desc)] if block_given?
    end
  end
end
