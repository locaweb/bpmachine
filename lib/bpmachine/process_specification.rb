module BPMachine
  module ProcessSpecification
    ::ProcessSpecification = BPMachine::ProcessSpecification
    
    def self.included(klass)
      has_status_reader = klass.instance_method(:status) rescue false
      klass.send(:attr_reader, :status) unless has_status_reader
      
      has_status_writer = klass.instance_method(:status=) rescue false
      klass.send(:attr_writer, :status) unless has_status_writer
      
      klass.extend ClassMethods
    end
    
    def change_status(new_status)
      @status = new_status
      self.save
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
        return state unless (transition[:if].nil? || self.send(transition[:if]))
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
            self.send(specification.before_action) unless specification.before_action.nil?
            raise InvalidInitialState, 
              "Process #{name} requires object to have status #{specification.pre_condition}, but it is #{state}" unless specification.applies_to? state
            execute_transitions_from specification
            self.send(specification.after_action) unless specification.after_action.nil?
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
        attr_reader :pre_condition, :before_action, :after_action
        
        def initialize
          @states = {}
        end
        
        def transition_for(state)
          @states[state]
        end
        
        def applies_to?(state)
          return true if @pre_condition.nil?
          @pre_condition == state
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

