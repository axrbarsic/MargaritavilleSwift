import AVFoundation
import SwiftUI

struct VoiceNoteBubble: View {
    let attachment: MediaAttachment
    private let fileStore = LocalMediaFileStore()

    @State private var player: AVAudioPlayer?
    @State private var playbackDelegate = VoiceNotePlaybackDelegate()
    @State private var isPlaying = false
    @State private var playbackError: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .background(OceanKeyTheme.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(timeLabel)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(OceanKeyTheme.accent.opacity(0.78))
                }

                Text(attachment.transcript?.isEmpty == false ? attachment.transcript! : "Голос сохранён без расшифровки")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let playbackError {
                    Text(playbackError)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.pending)
                }
            }
            .padding(12)
            .background(.black.opacity(0.30))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.16), lineWidth: 1)
            }
        }
        .onDisappear(perform: stopPlayback)
    }

    private var timeLabel: String {
        attachment.createdAt.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        do {
            if player == nil {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
                try session.setActive(true)

                let nextPlayer = try AVAudioPlayer(contentsOf: fileStore.url(for: attachment))
                playbackDelegate.onFinish = {
                    isPlaying = false
                    player = nil
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                }
                nextPlayer.delegate = playbackDelegate
                nextPlayer.prepareToPlay()
                player = nextPlayer
            }

            guard player?.play() == true else {
                playbackError = "Не удалось воспроизвести голос"
                isPlaying = false
                return
            }
            playbackError = nil
            isPlaying = true
        } catch {
            playbackError = error.localizedDescription
            isPlaying = false
            player = nil
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private final class VoiceNotePlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish?()
    }
}
