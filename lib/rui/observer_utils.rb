# Copyright (c) 2009-2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'observer'
require 'rui/utils'

#
# A mixin to make it easier to implement observers using the standard observer
# library.
#
# Mixing <tt>Observer</tt> into a class generates a default update method,
# which reacts to notification in the form of a hash, and calls appropriate
# event handlers, obtained by prepending "on_" to each key, and passing it the
# corresponding value.
#
# For example, an event containing the following data
#
#   { :pressed => { :x => 34, :y => 11 },
#     :released => { :x => 10, :y => 76 } }
#
# would result in the following method calls:
#
#   on_pressed(:x => 34, :y => 11)
#   on_released(:x => 10, :y => 76)
#
# As a special case, if an event takes more than 1 parameter, the corresponding
# value is assumed to be an array, and its elements are passed as arguments to
# the event.
#
module Observer
  #
  # A default implementation for the <tt>update</tt> function.
  #
  # Parses notification data and dispatches to the corresponding events.
  #
  def update(data)
    data.each_key do |key|
      m = begin
        method("on_#{key}")
      rescue NameError
      end
      
      if m
        case m.arity
        when 0
          m[]
        when 1
          m[data[key]]
        else
          m[*data[key]]
        end
      end
    end
  end
end

#
# Extensions to the standard Observable module of the observer library.
#
# This mixin allows to define event handlers dynamically, without having to
# create an Observer class for each handler.
#
# For example, assuming <tt>button</tt> is an instance of some observable class:
#
#   count = 0
#   button.on(:clicked) do
#     count += 1
#     puts "I have been clicked #{count} times"
#   end
#
# Events can be fired with the <tt>fire</tt> method, and support arbitrary
# arguments.
#
module Observable
  #
  # Alias to observe.
  #
  def on(event, &blk)
    observe(event, &blk)
  end
  
  #
  # Create a dynamic observer handling a given event.
  #
  # @param event [Symbol] the event to handle
  # @param &blk [Block] event handler
  # @return an observer object, which can be later used to remove
  #   the event handler.
  #
  def observe(event, &blk)
    obs = SimpleObserver.new(event, &blk)
    add_observer obs
    # return observer so that we can remove it later
    obs
  end
  
  # Create a limited observer handling a given event.
  #
  # A limited observer behaves similarly to a normal dynamic observer, but in
  # addition, it keeps track  of the return valur of the handler. When the
  # handler returns true, the observer is destroyed.
  #
  # @param event [Symbol] the event to handle
  # @param &blk [Block] event handler
  # @return an observer object, which can be later used to remove
  #   the event handler.
  #
  def observe_limited(event, &blk)
    obs = LimitedObserver.new(self, event, &blk)
    add_observer obs
    obs
  end

  #
  # Fire an event.
  #
  # @param e [Symbol, Hash] event and arguments. This needs to be either
  #   a Symbol, or a Hash with a single key corresponding to the event, and the
  #   value being the event data to pass to the handler.
  #
  def fire(e)
    changed
    notify_observers any_to_event(e)
  end
  
  private

  def any_to_event(e)
    if e.is_a? Symbol
      { e => nil }
    else
      e
    end
  end
end

class Proc
  def generic_call(args)
    case arity
    when 0
      call
    when 1
      call(args)
    else
      call(*args)
    end
  end
end

class SimpleObserver
  def initialize(event, &blk)
    @event = event
    @blk = blk
  end
  
  def update(data)
    if data.has_key?(@event)
      @blk.generic_call(data[@event])
    end
  end
end

class LimitedObserver < SimpleObserver
  def initialize(observed, event, &blk)
    super(event, &blk)
    @observed = observed
  end
  
  def update(data)
    remove = super(data)
    @observed.delete_observer(self) if remove
    remove
  end
end
