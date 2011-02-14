# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'rui/toolkits/qtbase/qt'

module KDE
  def self.ki18n(str)
    str
  end

  def self.i18n(str)
    str
  end
  
  def self.i18nc(context, str)
    str
  end
  
  def self.active_color
    $qApp.palette.color(Qt::Palette::Highlight)
  end
  
  def self.std_shortcut(name)
    code = Qt::KeySequence.send(name.to_s.capitalize)
    Qt::KeySequence.new(code)
  end
end

class Qt::UrlRequester < Qt::LineEdit
  def url=(val)
    self.text = val.to_string
  end
  
  def url
    Qt::Url.new(text)
  end
end

class Qt::MainWindow
  attr_reader :guis
  
  def initialize(parent)
    super(parent)
    
    setToolButtonStyle(Qt::ToolButtonFollowStyle)
    
    # create basic GUI
    @guis = []
    @gui = Qt::gui(:qt_base) do |g|
      g.menu_bar do |mb|
        mb.merge_point
        mb.menu(:settings, :text => KDE::i18n("&Settings"))
        mb.menu(:help, :text => KDE::i18n("&Help")) do |m|
          m.action :about
          m.action :about_qt
        end
      end
    end
  end
  
  def setGUI(gui)
    regular_action(:about, :text => KDE::i18n("&About")) do
      Qt::MessageBox.about(nil,
                           $qApp.data[:name],
                           [$qApp.data[:description],
                            $qApp.data[:copyright]].join("\n"))
    end
    regular_action(:about_qt, :text => KDE::i18n("About &Qt")) { $qApp.about_qt }
    
    @gui.merge!(gui)
    @guis.each {|g| @gui.merge! g }
    RUI::GuiBuilder.build(self, @gui)
    
    # restore state
    settings = Qt::Settings.new
    state = nil
    geometry = nil
    if settings.contains("mainwindow/state")
      state = settings.value("mainwindow/state").toByteArray
      geometry = settings.value("mainwindow/geometry").toByteArray
      restore_geometry(geometry)
      restore_state(state)
    end
  end

  def saveGUI
    settings = Qt::Settings.new
    settings.begin_group("mainwindow")
    settings.set_value("geometry", Qt::Variant.new(save_geometry))
    settings.set_value("state", Qt::Variant.new(save_state))
    settings.end_group
    settings.sync
  end
  
  def caption=(title)
    self.window_title = $qApp.application_name.capitalize + 
        " - " + title
  end
end

class Qt::Dialog
  include Layoutable
  
  def setGUI(gui)
    self.window_title = gui.opts[:caption]
    layout = Qt::VBoxLayout.new(self)
    widget = Qt::Widget.new(self)
    widget.owner = self
    widget.setGUI(gui)
    buttons = Qt::DialogButtonBox.new
    buttons.add_button(Qt::DialogButtonBox::Ok)
    buttons.add_button(Qt::DialogButtonBox::Cancel)
    layout.add_widget(widget)
    layout.add_widget(buttons)
    
    buttons.on(:accepted) { fire :ok_clicked; accept }
    buttons.on(:rejected) { reject }
  end
end

class Qt::XMLGUIClient < Qt::Object
  def setGUI(gui)
    parent.guis << gui
  end
end

module ActionHandler
  def action_collection
    @action_collection ||= { }
  end

  def action_list_entries
    @action_list_entries ||= Hash.new {|h, x| h[x] = [] }
  end

  def plug_action_list(name, actions)
    action_list_entries[name].each do |entry|
      actions.each do |action|
        entry.add_action(action)
      end
    end
  end

  def unplug_action_list(name)
    action_list_entries[name].each do |entry|
      entry.clear
    end
  end
  
  def add_action(name, a)
    action_parent.action_collection[name] = a
  end
  
  def std_action(name, &blk)
    text, icon_name = Qt::STD_ACTIONS[name]
    if text
      icon = Qt::Icon.from_theme(icon_name)
      a = Qt::Action.new(icon, text, action_parent)
      add_action(name, a)
      a.on(:triggered, &blk)
      a
    end
  end
  
  def regular_action(name, opts = { }, &blk)
    a = Qt::Action.new(opts[:text], action_parent)
    add_action(name, a)
    a.on(:triggered, &blk)
    if (opts[:icon])
      a.icon = Qt::Icon.from_theme(opts[:icon])
    end
    a.shortcut = opts[:shortcut] if opts[:shortcut]
    a.tool_tip = opts[:tooltip] if opts[:tooltip]
    a
  end
  
  def action_parent
    self
  end
end

module Qt
  STD_ACTIONS = {
    :undo => [KDE::i18n("&Undo"), 'edit-undo'],
    :redo => [KDE::i18n("&Redo"), 'edit-redo']
  }
  
  def self.gui(name, opts = { }, &blk)
    self.autogui(name, opts, &blk)
  end
end

class Qt::Application
  attr_accessor :data
  
  def self.init(data)
    data = { :id => data } unless data.is_a?(Hash)
    app = new(ARGV)
    app.application_name = data[:id]
    app.organization_name = data[:id]
    app.data = data

    if block_given?
      yield app
      app.exec
    end
    app
  end
end

class KDE::CmdLineArgs
  def self.parsed_args
    new(ARGV)
  end
  
  def initialize(args)
    @args = args
  end
  
  def [](i)
    @args[i]
  end
  
  def count
    @args.size
  end
  
  def is_set(name)
    false
  end
end

class KDE::Global
  def self.config
    Qt::Settings::Group.new(Qt::Settings.new, "")
  end
end

class Qt::Settings
  class Group
    def initialize(settings, prefix)
      @settings = settings
      @prefix = prefix
    end
    
    def exists
      in_group do
        not @settings.all_keys.empty?
      end
    end
    
    def delete_group
      @settings.remove(@prefix)
    end
      
    def group(name)
      Group.new(@settings, prefixed(name))
    end
    
    def write_entry(key, value)
      @settings.set_value(prefixed(key), 
                          Qt::Variant.new(value))
    end
    
    def read_entry(key, default_value = nil)
      @settings.value(prefixed(key)).toString || default_value
    end
    
    def sync
      @settings.sync
    end
    
    def group_list
      in_group do
        @settings.child_groups
      end
    end
    
    def entry_map
      in_group do
        @settings.child_keys.inject({}) do |res, key|
          res[key] = @settings.value(key).toString
          res
        end
      end
    end
    
    def each_group
      names = in_group do
        @settings.child_groups
      end
      names.each do |name|
        yield group(name)
      end
    end
    
    def name
      if @prefix =~ /\/([^\/]+)$/
        $1
      else
        @prefix
      end
    end
    
    private
    
    def prefixed(key)
      if @prefix.empty?
        key
      else
        [@prefix, key].join('/')
      end
    end
    
    def in_group
      @settings.begin_group(@prefix)
      result = yield
      @settings.end_group
      result
    end
  end
end

class Qt::TabWidget
  include Layoutable
end

class Qt::Process
  def output_channel_mode=(val)
    case val
    when :only_stdout
      setProcessChannelMode(Qt::Process::SeparateChannels)
      setReadChannel(Qt::Process::StandardOutput)
    else
      raise "Unsupported output mode #{val}"
    end
  end
  
  def self.split_args(str)
    str.split(/\s+/)
  end
  
  def run(path, args)
    start(path, args)
  end
end
