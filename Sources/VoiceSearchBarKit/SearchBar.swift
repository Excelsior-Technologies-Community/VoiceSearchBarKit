//
//  SearchBar.swift
//  VoiceSearchBarKit
//
//  Created by Noman Belim on 16/12/25.
//

import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: - SearchBar ViewModel (Debounce Logic)

final class SearchBarViewModel: ObservableObject {

    @Published var query: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let debounceTime: DispatchQueue.SchedulerTimeType.Stride
    private let onSearch: (String) -> Void

    init(
        debounceTime: Double = 0.5,
        onSearch: @escaping (String) -> Void
    ) {
        self.debounceTime = .milliseconds(Int(debounceTime * 1000))
        self.onSearch = onSearch
        setupDebounce()
    }

    private func setupDebounce() {
        $query
            .removeDuplicates()
            .debounce(for: debounceTime, scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.onSearch(text)
            }
            .store(in: &cancellables)
    }

    func clear() {
        query = ""
        onSearch("")
    }
}

// MARK: - Speech Recognizer (Voice Input)

final class SpeechRecognizer: NSObject, ObservableObject {

    @Published var isRecording = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    func start(onResult: @escaping (String) -> Void) throws {

        guard !audioEngine.isRunning else { return }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }

        let inputNode = audioEngine.inputNode
        request.shouldReportPartialResults = true

        task = speechRecognizer?.recognitionTask(with: request) { result, _ in
            if let text = result?.bestTranscription.formattedString {
                onResult(text)
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stop() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        isRecording = false
    }
}

// MARK: - SearchBar View (UI Component)

public struct SearchBarView: View {

    @StateObject private var viewModel: SearchBarViewModel
    @StateObject private var speech = SpeechRecognizer()

    @State private var voiceErrorMessage: String?
    @FocusState private var isFocused: Bool

    private let placeholder: String
    private let enableVoice: Bool

    // MARK: Initializer

    public init(
        placeholder: String = "Search",
        enableVoice: Bool = true,
        debounceTime: Double = 0.5,
        onSearch: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SearchBarViewModel(
                debounceTime: debounceTime,
                onSearch: onSearch
            )
        )
        self.placeholder = placeholder
        self.enableVoice = enableVoice
    }

    // MARK: View Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            HStack(spacing: 12) {

                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(placeholder, text: $viewModel.query)
                    .focused($isFocused)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)

                if enableVoice {
                    micButton
                }

                if !viewModel.query.isEmpty || speech.isRecording {
                    cancelButton
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .animation(.easeInOut, value: viewModel.query)
            .animation(.easeInOut, value: speech.isRecording)

            if let message = voiceErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Mic Button

    private var micButton: some View {
        Button {
            if speech.isRecording {
                speech.stop()
            } else {
                do {
                    try VoicePermissionValidator.validate()
                    speech.requestPermission()
                    try speech.start { text in
                        viewModel.query = text
                    }
                } catch {
                    voiceErrorMessage = error.localizedDescription
                    print(error.localizedDescription)
                }
            }
        } label: {
            Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                .foregroundColor(speech.isRecording ? .red : .blue)
        }
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button("Cancel") {
            cancelSearch()
        }
        .foregroundColor(.red)
        .transition(.opacity)
    }

    // MARK: - Actions

    private func cancelSearch() {
        viewModel.clear()
        speech.stop()
        isFocused = false
    }
}

// MARK: - Voice Permission Error

enum VoicePermissionError: LocalizedError {
    case missingPlistKeys

    var errorDescription: String? {
        """
        VoiceSearchBarKit Error:
        Missing required Info.plist keys.

        Please add:
        - NSSpeechRecognitionUsageDescription
        - NSMicrophoneUsageDescription
        """
    }
}

// MARK: - Voice Permission Validator

struct VoicePermissionValidator {

    static func validate() throws {
        let info = Bundle.main.infoDictionary

        let hasSpeechKey =
            info?["NSSpeechRecognitionUsageDescription"] != nil
        let hasMicKey =
            info?["NSMicrophoneUsageDescription"] != nil

        if !hasSpeechKey || !hasMicKey {
            throw VoicePermissionError.missingPlistKeys
        }
    }
}
