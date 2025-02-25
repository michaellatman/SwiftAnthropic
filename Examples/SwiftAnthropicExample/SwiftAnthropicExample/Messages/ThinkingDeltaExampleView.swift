//
//  ThinkingDeltaExampleView.swift
//  SwiftAnthropicExample
//
//  Created by AI on 5/15/24.
//

import SwiftAnthropic
import SwiftUI

struct ThinkingDeltaExampleView: View {
    @State private var service = AnthropicService(
        apiKey: UserDefaults.standard.string(forKey: "ANTHROPIC_API_KEY") ?? "")
    @State private var prompt: String = ""
    @State private var response: String = ""
    @State private var thinking: String = ""
    @State private var isLoading: Bool = false
    @State private var isThinkingEnabled: Bool = true
    @State private var thinkingBudget: Int = 16000
    @State private var showThinking: Bool = true

    var body: some View {
        VStack {
            Text("Claude 3.7 Sonnet with Thinking Deltas")
                .font(.title)
                .padding()

            TextEditor(text: $prompt)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .padding()

            Toggle("Enable Thinking", isOn: $isThinkingEnabled)
                .padding(.horizontal)

            if isThinkingEnabled {
                HStack {
                    Text("Thinking Budget (tokens):")
                    Slider(
                        value: Binding(
                            get: { Double(thinkingBudget) },
                            set: { thinkingBudget = Int($0) }
                        ), in: 1000...32000, step: 1000)
                    Text("\(thinkingBudget)")
                }
                .padding(.horizontal)
            }

            Button("Send") {
                Task {
                    await sendMessage()
                }
            }
            .padding()
            .disabled(prompt.isEmpty || isLoading)

            if isLoading {
                ProgressView()
                    .padding()
            }

            if !thinking.isEmpty && showThinking {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Thinking")
                            .font(.headline)
                            .foregroundColor(.purple)

                        Spacer()

                        Button(action: { showThinking.toggle() }) {
                            Image(systemName: showThinking ? "eye.slash" : "eye")
                        }
                    }

                    ScrollView {
                        Text(thinking)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .border(Color.purple, width: 1)
                }
                .padding()
            }

            ScrollView {
                Text(response)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .border(Color.gray, width: 1)
            .padding()

            Button("Clear") {
                response = ""
                thinking = ""
                prompt = ""
            }
            .padding()
        }
        .padding()
    }

    private func sendMessage() async {
        isLoading = true
        response = ""
        thinking = ""

        let message = MessageParameter.Message(
            role: .user,
            content: .text(prompt)
        )

        let parameters = MessageParameter(
            model: .claude37Sonnet,
            messages: [message],
            maxTokens: 4096,
            thinking: isThinkingEnabled
                ? MessageParameter.Thinking(budgetTokens: thinkingBudget) : nil
        )

        do {
            let stream = try await service.streamMessage(parameters)

            for try await event in stream {
                switch event.type {
                case MessageStreamResponse.StreamEvent.contentBlockDelta.rawValue:
                    if let text = event.delta?.text {
                        await MainActor.run {
                            response += text
                        }
                    }

                    if let thinkingText = event.delta?.thinking {
                        await MainActor.run {
                            thinking += thinkingText
                        }
                    }

                case MessageStreamResponse.StreamEvent.thinkingDelta.rawValue:
                    if let thinkingText = event.delta?.thinking {
                        await MainActor.run {
                            thinking += thinkingText
                        }
                    }

                default:
                    break
                }
            }

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                response = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    ThinkingDeltaExampleView()
}
