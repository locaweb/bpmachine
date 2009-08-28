module BPMachine
  module ProcessSpecification
    ::ProcessSpecification = BPMachine::ProcessSpecification
    
    def self.included(klass)
      klass.send(:attr_accessor, :status)
      klass.extend ClassMethods
    end
    
    def change_status(new_status)
      @status = new_status
    end
    
    def read_status
      @status.to_s.downcase.to_sym
    end
    
    private
    def execute_transitions_from(specification)
      while true
        state = read_status
        transition = specification.transition_for state
        return state if transition.nil?
        self.send transition[:method]
        change_status transition[:target]
      end
    end
    
    module ClassMethods
      def process(options = {}, &block)
        name = options[:of].to_sym
        specification = transitions_from block
        class_eval do
          define_method(name) do
            state = read_status
            raise InvalidInitialState, 
              "Process #{name} requires object to have status #{specification.pre_condition}, but it is #{state}" unless specification.applies_to? state
            execute_transitions_from specification
          end
        end
      end
      
      private
      def transitions_from(block)
        specification = SpecificationContext.new
        specification.instance_eval(&block)
        specification
      end
      
      class SpecificationContext
        attr_reader :pre_condition
        
        def initialize
          @states = {}
        end
        
        def transition_for(state)
          @states[state]
        end
        
        def applies_to?(state)
          @pre_condition == state
        end
        
        private
        def must_be(state)
          @pre_condition = state
        end
        
        def transition(name, options)
          origin = options[:from].to_sym
          target = options[:to].to_sym
          @states[origin] = { :target => target, :method => name }
        end
      end
    end
  end
end

