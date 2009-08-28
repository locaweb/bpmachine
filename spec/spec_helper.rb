require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  
  $LOAD_PATH.unshift(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'spec'
  require 'spec/autorun'

  Spec::Runner.configure do |config|

  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
  require 'bpmachine'
end

