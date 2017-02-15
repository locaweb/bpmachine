module BPMachine
  module ProcessSpecification
    def self.included(klass)
      klass.extend ClassMethods
    end

    def change_status(new_status)
      self.status = new_status
      self.save!
    end

    def read_status
      status.is_a?(Symbol) ? status : status.downcase.to_sym
    end

    private
    def execute_transitions_from(specification)
      while true
        state = read_status
        transition = specification.transition_for state
        return state if transition.nil?
        return state unless (transition[:if].nil? || self.send(transition[:if]))
        call_around(transition) { self.send transition[:method] }
        change_status transition[:target]
      end
    end

    def call_around(transition, &block)
      self.class.around_block.call(transition, self, block)
    end

    def execute_global_after_actions
      self.class.after_process_actions.each do |action|
        action.call self
      end
    end

    module ClassMethods
      def process(options = {}, &block)
        name = options[:of].to_sym
        load_step_definitions_for(name)

        specification = transitions_from block
        class_eval do
          define_method(name) do
            state = read_status
            self.send(specification.before_action) unless specification.before_action.nil?
            raise InvalidInitialState.new(name, specification.pre_condition, state) unless specification.applies_to? state
            execute_transitions_from specification
            self.send(specification.after_action) unless specification.after_action.nil?
            execute_global_after_actions
          end
        end
      end

      def after_processes(&block)
        after_process_actions << block
      end

      def after_process_actions
        @after_process_actions ||= []
      end

      def around(&block)
        @around_block = block
      end

      def around_block
        @around_block ||= -> (_transition, _instance, block) { block.call }
      end

      private
      def load_step_definitions_for(process_name)
        begin
          require "#{process_name}_steps"
          begin
            module_name = "#{process_name.to_s.camelize}Steps"
            steps_module = const_get(module_name)
            include(steps_module)
          rescue NameError
            Kernel.puts "WARNING: Error while trying to load the #{module_name} module, because it doesn't exist."
          end
        rescue LoadError
          nil
        end
      end

      def transitions_from(block)
        specification = SpecificationContext.new
        specification.instance_eval(&block)
        specification
      end

      class SpecificationContext
        attr_reader :pre_condition, :before_action, :after_action

        def initialize
          @states = {}
          @accepted_states = {}
        end

        def transition_for(state)
          @states[state] || @states[@accepted_states[state]]
        end

        def applies_to?(state)
          return true if @pre_condition.nil?
          @pre_condition == state || has_state?(state) || accept_state?(state)
        end

        def has_state?(state)
          not @states[state].nil?
        end

        def accept_state?(state)
          not @accepted_states[state].nil?
        end

        private
        def before(action)
          @before_action = action.to_sym
        end

        def after(action)
          @after_action = action.to_sym
        end

        def must_be(state)
          @pre_condition = state.to_sym
        end

        def accept_state(states, opts)
          [states].flatten.each {|state| @accepted_states[state] = opts[:as]}
        end

        def transition(name, options)
          origin = options[:from].to_sym
          target = options[:to].to_sym
          condition = options[:if].to_sym unless options[:if].nil?
          @states[origin] = { :target => target, :method => name, :if => condition }
        end
      end
    end
  end
end

ProcessSpecification = BPMachine::ProcessSpecification
