# frozen_string_literal: true

module ContentfulRedis
  module Error
    class ArgumentError < StandardError; end
    class RecordNotFound < StandardError; end
    class ClassNotFound < StandardError; end
    class InternalServerError < StandardError; end
  end
end
