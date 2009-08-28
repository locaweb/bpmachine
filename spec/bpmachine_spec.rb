require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Business Process execution engine" do
  it "should provide a DSL to describe processes" do
    
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
    
    machine = Machine.new
    machine.should_receive :remove_disks
    machine.should_receive :destroy_vm
    machine.should_receive :erase_data
    machine.uninstall
    
    machine.status.should be(:uninstalled)
  end
  
end
