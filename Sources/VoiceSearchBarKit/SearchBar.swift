//
//  SearchBar.swift
//  ImageSlider
//
//  Created by Noman belim on 16/12/25.
//

import Foundation
import Foundation
import Combine
import Foundation
import Combine
import SwiftUI

import Foundation
import Speech
import AVFoundation

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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
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


 
public struct SearchBarView: View {

    @StateObject private var viewModel: SearchBarViewModel
    @StateObject private var speech = SpeechRecognizer()

    @FocusState private var isFocused: Bool

    private let placeholder: String
    private let enableVoice: Bool

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
    public var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $viewModel.query)
                .focused($isFocused)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)

            if enableVoice {
                Button {
                    if speech.isRecording {
                        // *** MODIFICATION HERE ***
                        // If recording, tapping the mic cancels both the recording and the current query.
                        cancelSearch()
                    } else {
                        speech.requestPermission()
                        try? speech.start { text in
                            viewModel.query = text
                        }
                    }
                } label: {
                    Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                        .foregroundColor(speech.isRecording ? .red : .blue)
                }

            }

            if !viewModel.query.isEmpty || speech.isRecording {
                Button("Cancel") {
                    cancelSearch()
                }
                .foregroundColor(.red)
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .animation(.easeInOut, value: viewModel.query)
        // Add animation for the voice state change as well for a smoother transition
        .animation(.easeInOut, value: speech.isRecording)
    }

    private func cancelSearch() {
        viewModel.clear()
        speech.stop()
        isFocused = false
    }
 
}

