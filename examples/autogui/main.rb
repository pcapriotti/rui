require 'rui'

RUI::Application.init('autogui') do |app|
  widget = Qt::Widget.new
  widget.gui = RUI::autogui do
    layout(:type => :vertical) do
      button(:name => :quit, :text => "Quit")
    end
  end
  widget.quit.on(:clicked) { app.exit }
  widget.show
end
