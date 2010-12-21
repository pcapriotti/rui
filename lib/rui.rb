# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'rubygems' rescue nil
require 'rui/observer_utils'
require 'rui/utils'
require 'builder'

case ($toolkit || :kde)
when :qt
  require 'Qt4'
  KDE = Qt
  require 'rui/toolkits/qt/qt'
  RUI = Qt
when :kde
  require 'korundum4'
  require 'rui/toolkits/kde/kde'
  RUI = KDE
  module RUI
    def const_missing(c)
      Qt.const_get(c)
    end
  end
end

module KDE
  def self.autogui(name, opts = { }, &blk)
    Descriptor.build(:gui, opts.merge(:gui_name => name), &blk)
  end
end
