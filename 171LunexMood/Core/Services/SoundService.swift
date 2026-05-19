import AudioToolbox

enum SoundService {
    static func playSuccess() {
        guard GameProgressStore.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    static func playFail() {
        guard GameProgressStore.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1521)
    }
}
