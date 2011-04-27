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

  process :of => :install do
    must_be :initial_status
    accept_state [:activated, :installed], :as => :initial_status

    transition :create_disks,
      :from => :initial_status,
      :to => :diskless
  end

  process :of => :subprocess do
    must_be :ready_for_subprocess
    
    transition :step1,
      :from => :ready_for_subprocess,
      :to => :step1_done

    transition :step2,
      :from => :step1_done,
      :to => :subprocess_done
  end

  process :of => :execute_with_subprocess do
    must_be :ready_for_subprocess
    accept_state :step1_done, :as => :ready_for_subprocess
    
    transition :subprocess,
      :from => :ready_for_subprocess,
      :to => :subprocess_done

    transition :step3,
      :from => :subprocess_done,
      :to => :all_done
  end

  def save!
  end
end
