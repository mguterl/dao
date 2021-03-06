module Dao
  module Validations
    class Error < Dao::Error; end

    Dao.load('validations/validator.rb')
    Dao.load('validations/callback.rb')
    Dao.load('validations/common.rb')

    ClassMethods = proc do
      def validator
        @validator ||= Validator.new(self)
      end

      def validator=(validator)
        @validator = validator
      end

      %w(
        validations
        validates
      ).each do |method|
        module_eval <<-__, __FILE__, __LINE__
          def self.#{ method }(*args, &block)
            validator.#{ method }(*args, &block)
          end
        __
      end
    end

    InstanceMethods = proc do
      def validator
        @validator ||= Validator.new(self)
      end

      def validator=(validator)
        @validator = validator
      end

      %w(
        validations
        validates
        validated?
        validated!
        validate
        validate!
        run_validations!
        valid!
        forcing_validity?
        valid?
        errors
        status
      ).each do |method|
        module_eval <<-__, __FILE__, __LINE__
          def #{ method }(*args, &block)
            validator.#{ method }(*args, &block)
          end
        __
      end
    end

    def Validations.included(other)
      other.send(:instance_eval, &ClassMethods)
      other.send(:class_eval, &InstanceMethods)
      other.send(:include, Common)
      other.send(:extend, Common)
      super
    end
  end
end
