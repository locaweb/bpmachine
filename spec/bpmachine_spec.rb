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
  
end
