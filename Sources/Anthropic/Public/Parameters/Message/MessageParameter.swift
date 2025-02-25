//
//  MessageParameter.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/*
 Create a Message.
 Send a structured list of input messages, and the model will generate the next message in the conversation.
 Messages can be used for either single queries to the model or for multi-turn conversations.
 The Messages API is currently in beta. During beta, you must send the anthropic-beta: messages-2023-12-15 header in your requests. If you are using our client SDKs, this is handled for you automatically.
 */

/// [Create a message.](https://docs.anthropic.com/claude/reference/messages_post)
///  POST -  https://api.anthropic.com/v1/messages
public struct MessageParameter: Encodable {

   /// The model that will complete your prompt.
   // As we improve Claude, we develop new versions of it that you can query. The model parameter controls which version of Claude responds to your request. Right now we offer two model families: Claude, and Claude Instant. You can use them by setting model to "claude-2.1" or "claude-instant-1.2", respectively.
   /// See [models](https://docs.anthropic.com/claude/reference/selecting-a-model) for additional details and options.
   public let model: String

   /// Input messages.
   /// Our models are trained to operate on alternating user and assistant conversational turns. When creating a new Message, you specify the prior conversational turns with the messages parameter, and the model then generates the next Message in the conversation.
   /// Each input message must be an object with a role and content. You can specify a single user-role message, or you can include multiple user and assistant messages. The first message must always use the user role.
   /// If the final message uses the assistant role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.
   public let messages: [Message]

   /// The maximum number of tokens to generate before stopping.
   /// Note that our models may stop before reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
   /// Different models have different maximum values for this parameter. See [input and output](https://docs.anthropic.com/claude/reference/input-and-output-sizes) sizes for details.
   public let maxTokens: Int

   /// System prompt.
   /// A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.anthropic.com/claude/docs/how-to-use-system-prompts).
   /// System role can be either a simple String or an array of objects, use the objects array for prompt caching.
   /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
   public let system: System?

   /// An object describing metadata about the request.
   public let metadata: MetaData?

   /// Custom text sequences that will cause the model to stop generating.
   /// Our models will normally stop when they have naturally completed their turn, which will result in a response stop_reason of "end_turn".
   /// If you want the model to stop generating when it encounters custom strings of text, you can use the stop_sequences parameter. If the model encounters one of the custom sequences, the response stop_reason value will be "stop_sequence" and the response stop_sequence value will contain the matched stop sequence.
   public let stopSequences: [String]?

   /// Whether to incrementally stream the response using server-sent events.
   /// See [streaming](https://docs.anthropic.com/claude/reference/messages-streaming for details.
   public var stream: Bool

   /// Amount of randomness injected into the response.
   /// Defaults to 1. Ranges from 0 to 1. Use temp closer to 0 for analytical / multiple choice, and closer to 1 for creative and generative tasks.
   public let temperature: Double?

   /// Only sample from the top K options for each subsequent token.
   /// Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).
   public let topK: Int?

   /// Use nucleus sampling.
   /// In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by top_p. You should either alter temperature or top_p, but not both.
   public let topP: Double?

   /// Configure the model's thinking capabilities.
   /// This allows the model to perform more thorough analysis for complex problems.
   /// The budget_tokens parameter determines the maximum number of tokens Claude is allowed to use for its internal reasoning process.
   /// Note that budget_tokens must always be less than max_tokens.
   /// See [extended thinking](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking) for more details.
   public let thinking: Thinking?

   /// If you include tools in your API request, the model may return tool_use content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using tool_result content blocks.
   ///
   /// Each tool definition includes:
   ///
   /// **name**: Name of the tool.
   ///
   /// **description**: Optional, but strongly-recommended description of the tool.
   ///
   /// **input_schema**: JSON schema for the tool input shape that the model will produce in tool_use output content blocks.
   ///
   /// **cacheControl**: Prompt Caching
   let tools: [Tool]?

   ///   Forcing tool use
   ///
   ///    In some cases, you may want Claude to use a specific tool to answer the user's question, even if Claude thinks it can provide an answer without using a tool. You can do this by specifying the tool in the tool_choice field like so:
   ///
   ///    tool_choice = {"type": "tool", "name": "get_weather"}
   ///    When working with the tool_choice parameter, we have three possible options:
   ///
   ///    `auto` allows Claude to decide whether to call any provided tools or not. This is the default value.
   ///    `any` tells Claude that it must use one of the provided tools, but doesn't force a particular tool.
   ///    `tool` allows us to force Claude to always use a particular tool.
   let toolChoice: ToolChoice?

   public enum System: Encodable {
      case text(String)
      case list([Cache])

      public func encode(to encoder: Encoder) throws {
         var container = encoder.singleValueContainer()
         switch self {
         case .text(let string):
            try container.encode(string)
         case .list(let objects):
            try container.encode(objects)
         }
      }
   }

   public struct Message: Encodable {

      public let role: String
      public let content: Content

      public enum Role: String {
         case user
         case assistant
      }

      public enum Content: Encodable {

         case text(String)
         case list([ContentObject])

         // Custom encoding to handle different cases
         public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
               try container.encode(text)
            case .list(let objects):
               try container.encode(objects)
            }
         }

         public enum ContentObject: Encodable {
            case text(String)
            case image(ImageSource)
            case document(DocumentSource)
            case toolUse(String, String, MessageResponse.Content.Input)
            case toolResult(String, String, Bool?)
            case cache(Cache)

            // Custom encoding to handle different cases
            public func encode(to encoder: Encoder) throws {
               var container = encoder.container(keyedBy: CodingKeys.self)
               switch self {
               case .text(let text):
                  try container.encode("text", forKey: .type)
                  try container.encode(text, forKey: .text)
               case .image(let source):
                  try container.encode("image", forKey: .type)
                  try container.encode(source, forKey: .source)
               case .document(let document):
                  try container.encode("document", forKey: .type)
                  // Encode the full document structure
                  try container.encode(document.source, forKey: .source)
                  try container.encodeIfPresent(document.title, forKey: .title)
                  try container.encodeIfPresent(document.context, forKey: .context)
                  try container.encodeIfPresent(document.citations, forKey: .citations)
               case .toolUse(let id, let name, let input):
                  try container.encode("tool_use", forKey: .type)
                  try container.encode(id, forKey: .id)
                  try container.encode(name, forKey: .name)
                  try container.encode(input, forKey: .input)
               case .toolResult(let toolUseId, let content, let isError):
                  try container.encode("tool_result", forKey: .type)
                  try container.encode(toolUseId, forKey: .toolUseId)
                  try container.encode(content, forKey: .content)
                  try container.encodeIfPresent(isError, forKey: .isError)
               case .cache(let cache):
                  try container.encode(cache.type.rawValue, forKey: .type)
                  try container.encode(cache.text, forKey: .text)
                  if let cacheControl = cache.cacheControl {
                     try container.encode(cacheControl, forKey: .cacheControl)
                  }
               }
            }

            enum CodingKeys: String, CodingKey {
               case type
               case source
               case text
               case title
               case context
               case citations
               case id
               case name
               case input
               case toolUseId = "tool_use_id"
               case content
               case cacheControl = "cache_control"
               case isError = "is_error"
            }

            public static func toolResult(_ toolUseId: String, _ content: String) -> ContentObject {
               return .toolResult(toolUseId, content, nil)
            }
         }

         public struct ImageSource: Encodable {

            public let type: String
            public let mediaType: String
            public let data: String

            public enum MediaType: String, Encodable {
               case jpeg = "image/jpeg"
               case png = "image/png"
               case gif = "image/gif"
               case webp = "image/webp"
            }

            public enum ImageSourceType: String, Encodable {
               case base64
            }

            public init(
               type: ImageSourceType,
               mediaType: MediaType,
               data: String
            ) {
               self.type = type.rawValue
               self.mediaType = mediaType.rawValue
               self.data = data
            }
         }

         /// Represents a document source for PDF files to be processed by Claude.
         /// - Note: Maximum file size is 32MB and maximum page count is 100 pages.
         public struct DocumentSource: Encodable {
            /// The source information
            public let source: Source
            /// Optional title for the document
            public let title: String?
            /// Optional context for the document
            public let context: String?
            /// Optional citations configuration
            public let citations: Citations?

            public struct Source: Encodable {
               /// The type of document source
               public let type: String
               /// The media type of the document
               public let mediaType: String
               /// The document data
               public let data: String

               private enum CodingKeys: String, CodingKey {
                  case type
                  case mediaType = "media_type"
                  case data
               }
            }

            public enum DocumentError: Error {
               case exceededSizeLimit
               case invalidBase64Data
            }

            public enum MediaType: String, Encodable {
               case pdf = "application/pdf"
               case plainText = "text/plain"

               var maxSize: Int {
                  switch self {
                  case .pdf: return 32_000_000  // 32MB
                  case .plainText: return 32_000_000
                  }
               }
            }

            public enum DocumentSourceType: String, Encodable {
               case base64
               case text
            }

            public struct Citations: Encodable {
               public let enabled: Bool

               public init(enabled: Bool) {
                  self.enabled = enabled
               }
            }

            public init(
               type: DocumentSourceType = .base64,
               mediaType: MediaType,
               data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil
            ) throws {
               // For text type, no need to validate base64
               if type == .base64 {
                  // Validate base64 data
                  guard let decodedData = Data(base64Encoded: data) else {
                     throw DocumentError.invalidBase64Data
                  }

                  // Validate size limit
                  guard decodedData.count <= mediaType.maxSize else {
                     throw DocumentError.exceededSizeLimit
                  }
               }

               self.source = Source(
                  type: type.rawValue,
                  mediaType: mediaType.rawValue,
                  data: data
               )
               self.title = title
               self.context = context
               self.citations = citations
            }

            /// Creates a plain text document source
            public static func plainText(
               data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil
            ) throws -> DocumentSource {
               try DocumentSource(
                  type: .text,
                  mediaType: .plainText,
                  data: data,
                  title: title,
                  context: context,
                  citations: citations
               )
            }

            /// Creates a PDF document source
            public static func pdf(
               base64Data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil
            ) throws -> DocumentSource {
               try DocumentSource(
                  type: .base64,
                  mediaType: .pdf,
                  data: base64Data,
                  title: title,
                  context: context,
                  citations: citations
               )
            }
         }
      }

      public init(
         role: Role,
         content: Content
      ) {
         self.role = role.rawValue
         self.content = content
      }
   }

   public struct MetaData: Encodable {
      // An external identifier for the user who is associated with the request.
      // This should be a uuid, hash value, or other opaque identifier. Anthropic may use this id to help detect abuse. Do not include any identifying information such as name, email address, or phone number.
      public let userId: UUID
   }

   public struct ToolChoice: Codable {
      public enum ToolType: String, Codable {
         case tool
         case auto
         case any
      }

      let type: ToolType
      let name: String?
      let disableParallelToolUse: Bool?

      public init(
         type: ToolType,
         name: String? = nil,
         disableParallelToolUse: Bool? = nil
      ) {
         self.type = type
         self.name = name
         self.disableParallelToolUse = disableParallelToolUse
      }

      private enum CodingKeys: String, CodingKey {
         case type
         case name
         case disableParallelToolUse = "disable_parallel_tool_use"
      }
   }

   public struct Tool: Codable, Equatable {

      /// The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
      public let name: String
      /// A description of what the function does, used by the model to choose when and how to call the function.
      public let description: String?
      /// The parameters the functions accepts, described as a JSON Schema object. See the [guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) for examples, and the [JSON Schema reference](https://json-schema.org/understanding-json-schema) for documentation about the format.
      /// To describe a function that accepts no parameters, provide the value `{"type": "object", "properties": {}}`.
      public let inputSchema: JSONSchema?
      /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching#caching-tool-definitions)
      public let cacheControl: CacheControl?

      public struct JSONSchema: Codable, Equatable {

         public let type: JSONType
         public let properties: [String: Property]?
         public let required: [String]?
         public let pattern: String?
         public let const: String?
         public let enumValues: [String]?
         public let multipleOf: Int?
         public let minimum: Int?
         public let maximum: Int?

         private enum CodingKeys: String, CodingKey {
            case type, properties, required, pattern, const
            case enumValues = "enum"
            case multipleOf, minimum, maximum
         }

         public struct Property: Codable, Equatable {

            public let type: JSONType
            public let description: String?
            public let format: String?
            public let items: Items?
            public let required: [String]?
            public let pattern: String?
            public let const: String?
            public let enumValues: [String]?
            public let multipleOf: Int?
            public let minimum: Double?
            public let maximum: Double?
            public let minItems: Int?
            public let maxItems: Int?
            public let uniqueItems: Bool?

            private enum CodingKeys: String, CodingKey {
               case type, description, format, items, required, pattern, const
               case enumValues = "enum"
               case multipleOf, minimum, maximum
               case minItems, maxItems, uniqueItems
            }

            public init(
               type: JSONType,
               description: String? = nil,
               format: String? = nil,
               items: Items? = nil,
               required: [String]? = nil,
               pattern: String? = nil,
               const: String? = nil,
               enumValues: [String]? = nil,
               multipleOf: Int? = nil,
               minimum: Double? = nil,
               maximum: Double? = nil,
               minItems: Int? = nil,
               maxItems: Int? = nil,
               uniqueItems: Bool? = nil
            ) {
               self.type = type
               self.description = description
               self.format = format
               self.items = items
               self.required = required
               self.pattern = pattern
               self.const = const
               self.enumValues = enumValues
               self.multipleOf = multipleOf
               self.minimum = minimum
               self.maximum = maximum
               self.minItems = minItems
               self.maxItems = maxItems
               self.uniqueItems = uniqueItems
            }
         }

         public enum JSONType: String, Codable {
            case integer = "integer"
            case string = "string"
            case boolean = "boolean"
            case array = "array"
            case object = "object"
            case number = "number"
            case `null` = "null"
         }

         public struct Items: Codable, Equatable {

            public let type: JSONType
            public let properties: [String: Property]?
            public let pattern: String?
            public let const: String?
            public let enumValues: [String]?
            public let multipleOf: Int?
            public let minimum: Double?
            public let maximum: Double?
            public let minItems: Int?
            public let maxItems: Int?
            public let uniqueItems: Bool?

            private enum CodingKeys: String, CodingKey {
               case type, properties, pattern, const
               case enumValues = "enum"
               case multipleOf, minimum, maximum, minItems, maxItems, uniqueItems
            }

            public init(
               type: JSONType,
               properties: [String: Property]? = nil,
               pattern: String? = nil,
               const: String? = nil,
               enumValues: [String]? = nil,
               multipleOf: Int? = nil,
               minimum: Double? = nil,
               maximum: Double? = nil,
               minItems: Int? = nil,
               maxItems: Int? = nil,
               uniqueItems: Bool? = nil
            ) {
               self.type = type
               self.properties = properties
               self.pattern = pattern
               self.const = const
               self.enumValues = enumValues
               self.multipleOf = multipleOf
               self.minimum = minimum
               self.maximum = maximum
               self.minItems = minItems
               self.maxItems = maxItems
               self.uniqueItems = uniqueItems
            }
         }

         public init(
            type: JSONType,
            properties: [String: Property]? = nil,
            required: [String]? = nil,
            pattern: String? = nil,
            const: String? = nil,
            enumValues: [String]? = nil,
            multipleOf: Int? = nil,
            minimum: Int? = nil,
            maximum: Int? = nil
         ) {
            self.type = type
            self.properties = properties
            self.required = required
            self.pattern = pattern
            self.const = const
            self.enumValues = enumValues
            self.multipleOf = multipleOf
            self.minimum = minimum
            self.maximum = maximum
         }
      }

      public init(
         name: String,
         description: String?,
         inputSchema: JSONSchema?,
         cacheControl: CacheControl? = nil
      ) {
         self.name = name
         self.description = description
         self.inputSchema = inputSchema
         self.cacheControl = cacheControl
      }
   }

   /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
   public struct Cache: Encodable {
      let type: CacheType
      let text: String
      let cacheControl: CacheControl?

      public init(
         type: CacheType = .text,
         text: String,
         cacheControl: CacheControl?
      ) {
         self.type = type
         self.text = text
         self.cacheControl = cacheControl
      }

      public enum CacheType: String, Encodable {
         case text
      }
   }

   public struct CacheControl: Codable, Equatable {

      let type: CacheControlType

      public init(type: CacheControlType) {
         self.type = type
      }

      public enum CacheControlType: String, Codable {
         case ephemeral
      }
   }

   /// Configure the model's thinking capabilities.
   public struct Thinking: Encodable {
      /// The type of thinking to enable.
      public let type: ThinkingType

      /// The maximum number of tokens Claude is allowed to use for its internal reasoning process.
      /// Must be less than the max_tokens specified in the request.
      public let budgetTokens: Int

      public enum ThinkingType: String, Encodable {
         case enabled
      }

      public init(type: ThinkingType = .enabled, budgetTokens: Int) {
         self.type = type
         self.budgetTokens = budgetTokens
      }

      private enum CodingKeys: String, CodingKey {
         case type
         case budgetTokens = "budget_tokens"
      }
   }

   public init(
      model: Model,
      messages: [Message],
      maxTokens: Int,
      system: System? = nil,
      metadata: MetaData? = nil,
      stopSequences: [String]? = nil,
      stream: Bool = false,
      temperature: Double? = nil,
      topK: Int? = nil,
      topP: Double? = nil,
      thinking: Thinking? = nil,
      tools: [Tool]? = nil,
      toolChoice: ToolChoice? = nil
   ) {
      self.model = model.value
      self.messages = messages
      self.maxTokens = maxTokens
      self.system = system
      self.metadata = metadata
      self.stopSequences = stopSequences
      self.stream = stream
      self.temperature = temperature
      self.topK = topK
      self.topP = topP
      self.thinking = thinking
      self.tools = tools
      self.toolChoice = toolChoice
   }
}
