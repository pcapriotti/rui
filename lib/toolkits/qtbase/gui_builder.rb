# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

module Qt
  module GuiBuilder    
    def self.build(window, gui)
      Gui.new.build(window, nil, gui)
    end
    
    def build(window, parent, desc)
      element = create_element(window, parent, desc)
      desc.children.each do |child|
        b = builder(child.name).new
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
    
    class Gui
      include GuiBuilder
      def create_element(window, parent, desc)
        window
      end
    end
    
    class MenuBar
      include GuiBuilder
      
      def create_element(window, parent, desc)
        window.menu_bar
      end
    end
    
    class Menu
      include GuiBuilder
      
      def create_element(window, parent, desc)
        menu = Qt::Menu.new(desc.opts[:text].to_s, window)
        parent.add_menu(menu)
        menu
      end
    end
    
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
    
    class Separator
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent.add_separator
      end
    end
    
    class Group
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent
      end
    end
    
    class ActionList
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent
      end
    end
    
    class ToolBar
      include GuiBuilder
      
      def create_element(window, parent, desc)
        tb = Qt::ToolBar.new(desc.opts[:text].to_s, parent)
        tb.object_name = desc.opts[:name].to_s
        parent.add_tool_bar(Qt::TopToolBarArea, tb)
        tb
      end
    end
    
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
    
    class Stretch
      include GuiBuilder
      
      def create_element(window, parent, desc)
        parent.add_stretch
      end
    end
    
    class Label
      include GuiBuilder
      
      def create_element(window, parent, desc)
        label = Qt::Label.new(desc.opts[:text].to_s, window)
        setup_widget(label, window, parent, desc)
        if desc.opts[:buddy]
          window.buddies[label] = desc.opts[:buddy]
        end
        label
      end
    end
    
    class TabWidget
      include GuiBuilder
      
      def create_element(window, parent, desc)
        widget = KDE::TabWidget.new(window)
        setup_widget(widget, window, parent, desc)
        widget.owner = window.owner
        widget
      end
    end
    
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
          b = builder(child.name).new
          b.build(parent, Helper.new(parent, desc.opts[:text]), child)
        end
      end
    end
    
    class UrlRequester < Widget
      def factory(desc)
        KDE::UrlRequester
      end
    end

    class LineEdit < Widget
      def factory(desc)
        Qt::LineEdit
      end
    end
    
    class ComboBox < Widget
      def factory(desc)
        KDE::ComboBox
      end
    end
    
    class List < Widget
      def factory(desc)
        Qt::ListView
      end
    end
    
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
