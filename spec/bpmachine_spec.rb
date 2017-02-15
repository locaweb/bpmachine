require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the DSL for business process" do
  describe "automatic module loading" do
    it "should require a file named <process_name>_steps.rb if exists" do
      expect(Object).to be_const_defined(:UninstallSteps)
    end

    it "should include the steps definition module named <Process>Steps in the process declaring class" do
      expect(Machine.included_modules).to include(UninstallSteps)
    end

    it "should ignore step definition files that doesn't exist" do
      declaration = lambda do
        class ClassWithProcess
          include ProcessSpecification
          process :of => :anything do
            transition :some_event, :from => :initial, :to => :final
          end
        end
      end
      expect { declaration }.not_to raise_error
    end

    it "should ignore step definition files that doesn't exist" do
      declaration = lambda do
        class ClassWithWrongProcess
          include ProcessSpecification
          process :of => :wrong do
            transition :some_event, :from => :initial, :to => :final
          end
        end
      end
      expect(Kernel).not_to receive(:puts).with(/WrongSteps/)
      expect { declaration }.not_to raise_error
    end

  end

  it "should execute all transitions described in the process" do
    machine = Machine.new
    machine.status = :deactivated
    expect(machine).to receive(:machine_exists?).and_return true
    expect(machine).to receive(:remove_disks)
    expect(machine).to receive(:destroy_vm)
    expect(machine).to receive(:erase_data)

    machine.uninstall
    expect(machine.status).to eq :uninstalled
  end

  it "should not change state if condition fails" do
  	machine = Machine.new
  	machine.status = :deactivated
  	expect(machine).to receive(:machine_exists?).and_return false

  	machine.uninstall
  	machine.status = :deactivated
  end

  it "should stop execution when a transition fail" do
    machine = Machine.new
    machine.status = :deactivated
    expect(machine).to receive(:machine_exists?).and_return true
    expect(machine).to receive(:remove_disks)
    expect(machine).to receive(:destroy_vm).and_raise("execution fail")

    expect { machine.uninstall }.to raise_error("execution fail")
    expect(machine.status).to eq :diskless
  end

  it "should require the initial state" do
    machine = Machine.new
    machine.status = :activated

    expect { machine.uninstall }.to raise_error(InvalidInitialState,
        "Process uninstall requires object to have initial status deactivated or any transitional status, but it is activated")
  end

  it "should accept other states as determined state" do
    machine = Machine.new
    machine.status = :activated

    expect(machine).to receive(:create_disks)
    machine.install
  end

  it "should not accept unexpected stated" do
    machine = Machine.new
    machine.status = :deactivated
    expect { machine.install }.to raise_error(InvalidInitialState,
        "Process install requires object to have initial status initial_status or any transitional status, but it is deactivated")
  end

  it "should execute subprocess" do
    machine = Machine.new
    machine.status = :ready_for_subprocess
    expect(machine).to receive(:step1).ordered
    expect(machine).to receive(:step2).ordered
    expect(machine).to receive(:step3).ordered
    machine.execute_with_subprocess
    expect(machine.status).to eq :all_done
  end

  it "should resume a process stopped in a subprocess" do
    machine = Machine.new
    machine.status = :step1_done
    expect(machine).not_to receive(:step1)
    expect(machine).to receive(:step2).ordered
    expect(machine).to receive(:step3).ordered
    machine.execute_with_subprocess
    expect(machine.status).to eq :all_done
  end

  it "should allow the process to resume from a transitional state" do
    machine = Machine.new
    machine.status = :diskless
    expect(machine).not_to receive(:remove_disks)
    expect(machine).to receive(:destroy_vm).ordered
    expect(machine).to receive(:erase_data).ordered
    machine.uninstall
    expect(machine.status).to eq :uninstalled
  end

  it "should be case insensitive with status" do
    machine = Machine.new
    machine.status = :deactivated
    expect(machine).to receive(:machine_exists?).ordered.and_return true
    expect(machine).to receive(:remove_disks).ordered
    expect(machine).to receive(:destroy_vm).ordered
    expect(machine).to receive(:erase_data).ordered

    machine.uninstall
    expect(machine.status).to eq :uninstalled
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

      def save!
    	end
    end

    process = ProcessWithBeforeAction.new
    process.status = :initial
    expect(process).to receive(:do_action).ordered
    expect(process).to receive(:some_event).ordered
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
    process.status = :initial
    expect(process).to receive(:some_event).ordered
    expect(process).to receive(:do_action).ordered
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

      def save!
    	end
    end

    process = InitialStateNotRequired.new
    process.status = :initial
    expect(process).to receive(:some_event)
    process.anything
    expect(process.status).to eq :final

    second_process = InitialStateNotRequired.new
    second_process.status = :other
    expect(second_process).to receive(:other_event)
    second_process.anything
    expect(second_process.status).to eq :final
  end

  it "should accept global 'after' blocks, passing the object processing the flow" do
    machine = Class.new(Machine) do
      attr_accessor :process_object
      after_processes do |process_object|
        process_object.block_called
        process_object.process_object = process_object
      end
    end.new

    machine.status = :deactivated
    expect(machine).to receive(:machine_exists?).and_return true
    expect(machine).to receive(:remove_disks)
    expect(machine).to receive(:destroy_vm)
    expect(machine).to receive(:erase_data)
    expect(machine).to receive(:block_called)

    machine.uninstall

    expect(machine.process_object).to be(machine)
  end

  describe "should accept 'around' blocks" do
    let(:machine) do
      c = Class.new(Machine) do
        around do |_transition, instance, block|
          instance.begin_around
          block.call
          instance.end_around
        end
      end

      c.new.tap { |m| m.status = :deactivated }
    end

    it 'runs the workflow with the around block' do
      expect(machine).to receive(:machine_exists?).and_return true
      expect(machine).to receive(:remove_disks)
      expect(machine).to receive(:destroy_vm)
      expect(machine).to receive(:erase_data)

      expect(machine).to receive(:begin_around).exactly(3).times
      expect(machine).to receive(:end_around).exactly(3).times

      machine.uninstall
    end
  end

  it "should raise error when model can't be saved" do
    class TheProcess
      include ProcessSpecification

      attr_accessor :status

      process :of => :anything do
        transition :some_event, :from => :initial, :to => :final
        transition :other_event, :from => :other, :to => :final
      end

      def save!
        raise "Big Error!"
    	end
    end

    process = TheProcess.new
    process.status = :initial
    allow(process).to receive(:some_event)
    allow(process).to receive(:other_event)
    expect { process.anything }.to raise_error("Big Error!")
  end

end
