# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'rui/factory'

module RUI
  #
  # Helper module used to interpret a GUI descriptor and build a Qt GUI.
  #
  # Classes in this module correspond to valid descriptor tags.
  #
  module GuiBuilder    
    def self.build(window, gui)
      Gui.new.build(window, nil, gui)
    end
    
    def build(window, parent, desc)
      element = create_element(window, parent, desc)
      desc.children.each do |child|
        b = builder(child.tag).new
        b.build(window, element, child)
      end
      element
    end
    
    def setup_widget(widget, parent, layout, desc)
      layout.add_widget(widget)
      if desc.opts[:name]
        parent.add_accessor(desc.opts[:name], widget)
      end        
    end
    
    def builder(name)
      GuiBuilder.const_get(name.to_s.capitalize.camelize)
    end
    
    #
    # Root tag for a GUI descriptor.
    #
    # Created automatically by {RUI.autogui}.
    #
    class Gui
      include GuiBuilder
      def create_element(window, parent, desc)
        window
      end
    end
    
    #
    # Menu bar.
    #
    # This tag must be a child of a gui descriptor.
    #
    class MenuBar
      include GuiBuilder
      
      def create_element(window, parent, desc)
        window.menu_bar
      end
    end
    
    #
    # A menu.
    #
    # This tag must be a child of a menu_bar descriptor.
    #
    class Menu
      include GuiBuilder
      
      def create_element(window, parent, desc)
        menu = Qt::Menu.new(desc.opts[:text].to_s, window)
        parent.add_menu(menu)
        menu
      end
    end
    
    #
    # Menu or toolbar action.
    #
    # This tag must be a child of a menu or toolbar descriptor.
    #
    class Action
      include GuiBuilder
      
      def create_element(window, parent, desc)
        action = window.action_collection[desc.opts[:name]]
        if action
          parent.add_action(action)
        end
        action
      end
    end
    
    #
    # Menu or toolbar separator.
    #
    # This tag must be a child of a menu or toolbar descriptor.
    #
    class Separator
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent.add_separator
      end
    end
    
    #
    # A descriptor group.
    #
    # This can be used to affect how merging of descriptor is performed
    # (together with merge points).
    #
    # @see Descriptor
    #
    class Group
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent
      end
    end
    
    #
    # An action list is a placeholder for dynamically pluggable actions.
    #
    # Action lists can be plugged by using {ActionHandler#plug_action_list} and
    # removed with {ActionHandler#unplug_action_list}.
    #
    class ActionList
      include GuiBuilder

      class Entry
        attr_reader :parent

        def initialize(parent)
          @parent = parent
          @actions = []
        end

        def add_action(action)
          @parent.add_action(action)
          @actions << action
        end

        def clear
          @actions.each do |action|
            action.dispose
          end
          @actions = []
        end
      end
      
      def create_element(window, parent, desc)
        entry = Entry.new(parent)
        window.action_list_entries[desc.opts[:name]] << entry
        parent
      end
    end
    
    #
    # A toolbar.
    #
    # This tag must be a child of a gui descriptor.
    #
    class ToolBar
      include GuiBuilder
      
      def create_element(window, parent, desc)
        tb = Qt::ToolBar.new(desc.opts[:text].to_s, parent)
        tb.object_name = desc.opts[:name].to_s
        parent.add_tool_bar(Qt::TopToolBarArea, tb)
        tb
      end
    end
    
    #
    # A widget layout.
    #
    # Two orientations are supported: horizontal and vertical. The orientation
    # is controlled by the <tt>type</tt> attribute of this descriptor.
    #
    # A margin can also be specified using the <tt>margin</tt> attribute.
    #
    class Layout
      include GuiBuilder
      
      def create_element(window, parent, desc)
        factory = if desc.opts[:type] == :horizontal
          Qt::HBoxLayout
        else
          Qt::VBoxLayout
        end
        layout = factory.new
        layout.margin = desc.opts[:margin] if desc.opts[:margin]
        parent.add_layout(layout)
        layout
      end
    end
    
    #
    # A stretch element.
    #
    # Used to separate consecutive elements of a layout.
    #
    class Stretch
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent.add_stretch
      end
    end
    
    #
    # A label.
    #
    # The label text is specified by the <tt>text</tt> attribute.
    #
    # A label image may be specified by the <tt>image</tt> attribute.
    #
    # A <tt>buddy</tt> attribute can also be specified as a widget id. The widget with
    # the given id will be set as the buddy of this label as GUI construction
    # time.
    #
    class Label
      include GuiBuilder
      
      def create_element(window, parent, desc)
        label = Qt::Label.new(desc.opts[:text].to_s, window)
        if desc.opts[:image]
          label.pixmap = desc.opts[:image].to_pix
        end
        setup_widget(label, window, parent, desc)
        if desc.opts[:buddy]
          window.buddies[label] = desc.opts[:buddy]
        end
        label
      end
    end
    
    #
    # A TabWidget.
    #
    class TabWidget
      include GuiBuilder
      
      def create_element(window, parent, desc)
        widget = KDE::TabWidget.new(window)
        setup_widget(widget, window, parent, desc)
        widget.owner = window.owner
        widget
      end
    end
    
    #
    # A generic widget.
    #
    # To use this tag, the <tt>factory</tt> descriptor property must be set to
    # the Factory to use to create the widget. The {Factory} class can be
    # useful when the widget to create needs special initialization. Note that
    # the given factory will be invoked passing only the parent widget as a
    # parameter, so any extra parameters must be preset by the factory itself.
    #
    class Widget
      include GuiBuilder
      
      def create_element(window, parent, desc)
        widget = factory(desc).new(window)
        setup_widget(widget, window, parent, desc)
        widget
      end
      
      def factory(desc)
        desc.opts[:factory]
      end
    end
    
    #
    # An individual tab in a tab_widget.
    #
    # This tag must be a child of tab_widget descriptor.
    #
    class Tab
      include GuiBuilder
      
      class Helper
        def initialize(parent, text)
          @parent = parent
          @text = text
        end
        
        def add_widget(widget)
          @parent.add_tab(widget, @text)
        end
      end
      
      def build(window, parent, desc)
        desc.children.each do |child|
          b = builder(child.tag).new
          b.build(parent, Helper.new(parent, desc.opts[:text]), child)
        end
      end
    end
    
    #
    # A url requester widget.
    #
    class UrlRequester < Widget
      def factory(desc)
        KDE::UrlRequester
      end
    end

    #
    # A line edit widget.
    #
    class LineEdit < Widget
      def factory(desc)
        Qt::LineEdit
      end
    end
    
    #
    # A combobox.
    #
    class ComboBox < Widget
      def factory(desc)
        KDE::ComboBox
      end
    end
    
    #
    # A list widget.
    #
    class List < Widget
      def factory(desc)
        Qt::ListView
      end
    end
    
    #
    # A checkbox.
    #
    # The <tt>checked</tt> property specifies whether the checkbox is checked.
    #
    class CheckBox < Widget
      def factory(desc)
        Factory.new do |parent|
          check = Qt::CheckBox.new(parent)
          check.text = desc.opts[:text].to_s
          check.checked = desc.opts[:checked]
          check
        end
      end
    end
    
    #
    # A push button.
    #
    class Button < Widget
      def factory(desc)
        Factory.new do |parent|
          KDE::PushButton.new(KDE::Icon.from_theme(desc.opts[:icon]), 
                              desc.opts[:text], parent)
        end
      end
    end
  end
end
