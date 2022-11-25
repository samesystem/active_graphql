# frozen_string_literal: true

module GraphQL
  class Client
    def self.dump_schema(schema, io = nil, context: {})
      unless schema.respond_to?(:execute)
        raise TypeError, "expected schema to respond to #execute(), but was #{schema.class}"
      end

      result = schema.execute(
        document: IntrospectionDocument,
        operation_name: "IntrospectionQuery",
        variables: {},
        context: context
      )

      result = JSON.parse(result) if result.is_a?(String)

      if io
        io = File.open(io, "w") if io.is_a?(String)
        io.write(JSON.pretty_generate(result))
        io.close_write
      end

      result
    end

    def query(definition, variables: {}, context: {})
      raise NotImplementedError, "client network execution not configured" unless execute

      unless definition.is_a?(OperationDefinition)
        raise TypeError, "expected definition to be a #{OperationDefinition.name} but was #{document.class.name}"
      end

      if allow_dynamic_queries == false && definition.name.nil?
        raise DynamicQueryError, "expected definition to be assigned to a static constant https://git.io/vXXSE"
      end

      variables = deep_stringify_keys(variables)

      document = definition.document
      operation = definition.definition_node

      payload = {
        document: document,
        operation_name: operation.name,
        operation_type: operation.operation_type,
        variables: variables,
        context: context
      }

      result = ActiveSupport::Notifications.instrument("query.graphql", payload) do
        execute.execute(
          document: document,
          operation_name: operation.name,
          variables: variables,
          context: context
        )
      end

      result = JSON.parse(result) if result.is_a?(String)

      deep_freeze_json_object(result)

      data, errors, extensions = result.values_at("data", "errors", "extensions")

      errors ||= []
      errors = errors.map(&:dup)
      GraphQL::Client::Errors.normalize_error_paths(data, errors)

      errors.each do |error|
        error_payload = payload.merge(message: error["message"], error: error)
        ActiveSupport::Notifications.instrument("error.graphql", error_payload)
      end

      Response.new(
        result,
        data: definition.new(data, Errors.new(errors, ["data"])),
        errors: Errors.new(errors),
        extensions: extensions
      )
    end
  end
end
