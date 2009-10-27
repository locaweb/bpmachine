require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the DSL for business process" do

  class Machine
    include ProcessSpecification
    
    attr_accessor :status
    
    process :of => :uninstall do
      must_be :deactivated
      
      transition :remove_disks, 
        :from => :deactivated, 
        :to => :diskless,
     		:if => :machine_exists?
      
      transition :destroy_vm, 
        :from => :diskless, 
        :to => :vm_destroyed
      
      transition :erase_data, 
        :from => :vm_destroyed, 
        :to => :uninstalled
    end
    
    def save
    end
  end

  it "should execute all transitions described in the process" do
    machine = Machine.new
    machine.status = "DEACTIVATED"
    machine.should_receive(:machine_exists?).and_return true
    machine.should_receive :remove_disks
    machine.should_receive :destroy_vm
    machine.should_receive :erase_data
    
    machine.uninstall
    machine.status.should == "UNINSTALLED"
  end
  
  it "should not change state if condition fails" do
  	machine = Machine.new
  	machine.status = "DEACTIVATED"
  	machine.should_receive(:machine_exists?).and_return false
  	
  	machine.uninstall
  	machine.status = "DEACTIVATED"
  end
  
  it "should stop execution when a transition fail" do
    machine = Machine.new
    machine.status = "DEACTIVATED"
    machine.should_receive(:machine_exists?).and_return true
    machine.should_receive :remove_disks
    machine.should_receive(:destroy_vm).and_raise("execution fail")
    
    lambda { machine.uninstall }.should raise_error("execution fail")
    machine.status.should == "DISKLESS"
  end
  
  it "should require the initial state" do
    machine = Machine.new
    machine.status = "ACTIVATED"
    
    lambda { machine.uninstall }.should raise_error(InvalidInitialState, 
        "Process uninstall requires object to have status deactivated, but it is activated")
  end
  
  it "should be case insensitive with status" do
    machine = Machine.new
    machine.status = "DEACTIVATED"
    machine.should_receive(:machine_exists?).ordered.and_return true
    machine.should_receive(:remove_disks).ordered
    machine.should_receive(:destroy_vm).ordered
    machine.should_receive(:erase_data).ordered
    
    machine.uninstall
    machine.status.should == "UNINSTALLED"
  end
  
  it "should support custom code to be run before process start" do
    class ProcessWithBeforeAction
      include ProcessSpecification
      
      attr_accessor :status
      
      process :of => :anything do
        before :do_action
        must_be :initial
        transition :some_event, :from => :initial, :to => :final
      end
      
      def save
    	end
    end
    
    process = ProcessWithBeforeAction.new
    process.status = "INITIAL"
    process.should_receive(:do_action).ordered
    process.should_receive(:some_event).ordered
    process.anything
  end
  
  it "should support custom code to be run after process start" do
    class ProcessWithBeforeAction
      include ProcessSpecification
      
      process :of => :anything do
        after :do_action
        must_be :initial
        transition :some_event, :from => :initial, :to => :final
      end
    end
    
    process = ProcessWithBeforeAction.new
    process.status = "INITIAL"
    process.should_receive(:some_event).ordered
    process.should_receive(:do_action).ordered
    process.anything
  end
  
  it "should accept any initial state if there isn't a must_be rule" do
    class InitialStateNotRequired
      include ProcessSpecification
      
      attr_accessor :status
      
      process :of => :anything do
        transition :some_event, :from => :initial, :to => :final
        transition :other_event, :from => :other, :to => :final
      end
      
      def save
    	end
    end
    
    process = InitialStateNotRequired.new
    process.status = "INITIAL"
    process.should_receive :some_event
    process.anything
    process.status.should == "FINAL"

    second_process = InitialStateNotRequired.new
    second_process.status = "OTHER"
    second_process.should_receive :other_event
    second_process.anything
    second_process.status.should == "FINAL"
  end

  it "should accept global 'after' blocks, passing the object processing the flow" do
    machine = Machine.new
    
    called = false
    ProcessSpecification.after_processes do |process_object|
      called = true
      process_object.should be(machine)
    end

    machine.status = "DEACTIVATED"
    machine.should_receive(:machine_exists?).and_return true
    machine.should_receive :remove_disks
    machine.should_receive :destroy_vm
    machine.should_receive :erase_data
    machine.uninstall

    called.should be_true
  end
  
end
