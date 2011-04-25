require 'active_support/core_ext/string/inflections'
require 'bpmachine/process_specification'

class InvalidInitialState < Exception
  def initialize(name, expected_status, current_status)
    @name = name
    @expected_status = expected_status
    @current_status = current_status
  end

  def message
    "Process #{@name} requires object to have initial status #{@expected_status} or any transitional status, but it is #{@current_status}"
  end
end
