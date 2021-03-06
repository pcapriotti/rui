# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rui}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paolo Capriotti"]
  s.date = %q{2011-01-01}
  s.description = %q{GUI abstraction library supporting Qt and KDE backends}
  s.email = %q{p.capriotti@gmail.com}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".document",
    "COPYING",
    "Gemfile",
    "Gemfile.lock",
    "README.md",
    "Rakefile",
    "VERSION",
    "examples/autogui/main.rb",
    "examples/hello/main.rb",
    "examples/kderun.rb",
    "examples/qtrun.rb",
    "examples/signals/main.rb",
    "lib/rui.rb",
    "lib/rui/descriptor.rb",
    "lib/rui/factory.rb",
    "lib/rui/observer_utils.rb",
    "lib/rui/toolkits/kde/kde.rb",
    "lib/rui/toolkits/qt/qt.rb",
    "lib/rui/toolkits/qtbase/gui_builder.rb",
    "lib/rui/toolkits/qtbase/qt.rb",
    "lib/rui/utils.rb",
    "rui.gemspec",
    "test/helper.rb",
    "test/test_descriptor.rb",
    "test/test_factory.rb",
    "test/test_observer_utils.rb"
  ]
  s.homepage = %q{http://github.com/pcapriotti/rui}
  s.licenses = ["LGPL"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{nowarning}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{GUI abstraction library}
  s.test_files = [
    "examples/autogui/main.rb",
    "examples/hello/main.rb",
    "examples/kderun.rb",
    "examples/qtrun.rb",
    "examples/signals/main.rb",
    "test/helper.rb",
    "test/test_descriptor.rb",
    "test/test_factory.rb",
    "test/test_observer_utils.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<bluecloth>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bluecloth>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bluecloth>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

