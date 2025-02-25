//
//  ExtendedThinkingDemoView.swift
//  SwiftAnthropicExample
//
//  Created by AI on 5/15/24.
//

import SwiftAnthropic
import SwiftUI

struct ExtendedThinkingDemoView: View {
    @State private var service = AnthropicService(
        apiKey: UserDefaults.standard.string(forKey: "ANTHROPIC_API_KEY") ?? "")
    @State private var observable = MessageDemoObservable(
        service: AnthropicService(
            apiKey: UserDefaults.standard.string(forKey: "ANTHROPIC_API_KEY") ?? ""))
    @State private var prompt: String = ""
    @State private var isThinkingEnabled: Bool = true
    @State private var thinkingBudget: Int = 16000

    var body: some View {
        VStack {
            Text("Claude 3.7 Sonnet with Extended Thinking")
                .font(.title)
                .padding()

            TextEditor(text: $prompt)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .padding()

            Toggle("Enable Extended Thinking", isOn: $isThinkingEnabled)
                .padding()

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
            .disabled(prompt.isEmpty || observable.isLoading)

            if observable.isLoading {
                ProgressView()
                    .padding()
            }

            if !observable.thinking.isEmpty && isThinkingEnabled {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Thinking")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }

                    ScrollView {
                        Text(observable.thinking)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .border(Color.purple, width: 1)
                }
                .padding()
            }

            ScrollView {
                Text(observable.message)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .border(Color.gray, width: 1)
            .padding()

            if !observable.errorMessage.isEmpty {
                Text(observable.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Clear") {
                observable.clearMessage()
                prompt = ""
            }
            .padding()
        }
        .padding()
    }

    private func sendMessage() async {
        observable.clearMessage()

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
            try await observable.streamMessage(parameters: parameters)
        } catch {
            observable.errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ExtendedThinkingDemoView()
}
