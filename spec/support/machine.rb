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

  def save!
  end
end
