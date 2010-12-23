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
  module RUI
    MainWindow = KDE::XmlGuiWindow

    def self.const_missing(c)
      if KDE.const_defined?(c)
        KDE.const_get(c)
      else
        Qt.const_get(c)
      end
    end
  end
end

module RUI
  #
  # Create a GUI descriptor using the descriptor DSL.
  #
  # A GUI descriptor, as returned by this function, can be applied to a Widget
  # by settings the widget's gui property to it. For example:
  #
  #   widget.gui = RUI::autogui do
  #     button(:text => "Hello world")
  #   end
  #
  # See {Descriptor} for more details on the general descriptor DSL.
  #
  # See {RUI::GuiBuilder} for a list of supported descriptor tags for GUI
  # descriptors.
  #
  def self.autogui(name = :gui, opts = { }, &blk)
    Descriptor.build(:gui, opts.merge(:gui_name => name), &blk)
  end
end
