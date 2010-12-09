# Copyright (c) 2010 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.

require 'rui'

RUI::Application.init('signals') do |app|
  button = RUI::PushButton.new("Quit")
  button.on(:clicked) { app.exit }
  button.show
end

