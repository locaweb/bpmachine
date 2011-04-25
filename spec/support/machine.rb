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

  def save!
  end
end
