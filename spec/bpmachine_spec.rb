require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the DSL for business process" do

  class Machine
    include ProcessSpecification
    
    process :of => :uninstall do
      must_be :deactivated
      
      transition :remove_disks, 
        :from => :deactivated, 
        :to => :diskless
      
      transition :destroy_vm, 
        :from => :diskless, 
        :to => :vm_destroyed
      
      transition :erase_data, 
        :from => :vm_destroyed, 
        :to => :uninstalled
    end
  end

  it "should execute all transitions described in the process" do
    machine = Machine.new
    machine.status = :deactivated
    machine.should_receive :remove_disks
    machine.should_receive :destroy_vm
    machine.should_receive :erase_data
    
    machine.uninstall
    machine.status.should == :uninstalled
  end
  
  it "should stop execution when a transition fail" do
    machine = Machine.new
    machine.status = :deactivated
    machine.should_receive :remove_disks
    machine.should_receive(:destroy_vm).and_raise("execution fail")
    
    lambda { machine.uninstall }.should raise_error("execution fail")
    machine.status.should == :diskless
  end
  
  it "should require the initial state" do
    machine = Machine.new
    machine.status = :activated
    
    lambda { machine.uninstall }.should raise_error(InvalidInitialState, 
        "Process uninstall requires object to have status deactivated, but it is activated")
  end
  
  it "should be case insensitive with status" do
    machine = Machine.new
    machine.status = "DEACTIVATED"
    machine.should_receive :remove_disks
    machine.should_receive :destroy_vm
    machine.should_receive :erase_data
    
    machine.uninstall
    machine.status.should == :uninstalled
  end
  
  it "should support custom code to be run before process start"
  
  it "should accept any initial state if there isn't a must_be rule" do
    class ProcessWithBeforeAction
      include ProcessSpecification
      
      process :of => :anything do
        transition :some_event, :from => :initial, :to => :final
        transition :other_event, :from => :other, :to => :final
      end
    end
    
    process = ProcessWithBeforeAction.new
    process.status = :initial
    process.should_receive :some_event
    process.anything
    process.status.should == :final

    second_process = ProcessWithBeforeAction.new
    second_process.status = :other
    second_process.should_receive :other_event
    second_process.anything
    second_process.status.should == :final
  end
  
  it "shoud define status accessor by default" do
    class WithoutAccessor
      include ProcessSpecification
    end
    wa = WithoutAccessor.new
    wa.should respond_to(:status)
    wa.should respond_to(:status=)
    wa.status = :created
    wa.status.should == :created
  end
  
  it "should not override status accessor when already defined" do
    class WithReader
      def status
        :dont_override_please
      end
      include ProcessSpecification
    end
    reader = WithReader.new
    reader.status.should == :dont_override_please
    
    class WithWriter
      def status=(other)
        :dont_override_please
      end
      include ProcessSpecification
    end
    writer = WithWriter.new
    writer.status = :trying_to_change
    writer.status.should be_nil
  end
  
end
