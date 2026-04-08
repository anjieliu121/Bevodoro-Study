//
//  MusicManager.swift
//  Bevodoro Study
//
//  Created by 阿清 on 3/8/26.
//

import AVFoundation

/// Singleton that manages looping background music for the app.
/// Only one instance and one AVAudioPlayer exist; music continues across view controller changes.
final class MusicManager {

    static let shared = MusicManager()

    private static let userDefaultsKey = "backgroundMusicEnabled"
    private static let defaultMusicEnabled = true
    private static let musicVolumeKey = "backgroundMusicVolume"
    private static let defaultMusicVolume: Float = 0.8

    private var player: AVAudioPlayer?
    private let queue = DispatchQueue(label: "com.bevodoro.musicmanager", qos: .userInitiated)

    /// Whether background music is enabled (persisted in UserDefaults).
    var isMusicEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: MusicManager.userDefaultsKey) == nil {
                return MusicManager.defaultMusicEnabled
            }
            return UserDefaults.standard.bool(forKey: MusicManager.userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MusicManager.userDefaultsKey)
        }
    }

    /// Background music volume (0 = mute). Persisted in UserDefaults.
    var musicVolume: Float {
        get {
            if let v = UserDefaults.standard.object(forKey: MusicManager.musicVolumeKey) as? Float {
                return max(0, min(1, v))
            }
            if let n = UserDefaults.standard.object(forKey: MusicManager.musicVolumeKey) as? NSNumber {
                return max(0, min(1, n.floatValue))
            }
            return MusicManager.defaultMusicVolume
        }
        set {
            UserDefaults.standard.set(max(0, min(1, newValue)), forKey: MusicManager.musicVolumeKey)
        }
    }

    private init() {
        queue.async { [weak self] in
            self?.setupPlayer()
        }
    }

    private func setupPlayer() {
        guard player == nil else { return }

        let url: URL? = Bundle.main.url(forResource: "CloudCountry", withExtension: "mp3", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "CloudCountry", withExtension: "mp3")

        guard let url = url else {
            #if DEBUG
            print("MusicManager: CloudCountry.mp3 not found in bundle.")
            #endif
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("MusicManager: Failed to set audio session: \(error)")
            #endif
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = musicVolume
            p.prepareToPlay()
            player = p
        } catch {
            #if DEBUG
            print("MusicManager: Failed to create player: \(error)")
            #endif
        }
    }

    /// Starts background music if enabled. Does nothing if already playing.
    func playMusic() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.setupPlayer()
            guard self.isMusicEnabled, self.musicVolume > 0, let p = self.player, !p.isPlaying else { return }
            p.volume = self.musicVolume
            p.play()
        }
    }

    /// Stops background music.
    func stopMusic() {
        queue.async { [weak self] in
            self?.player?.stop()
        }
    }

    /// Sets volume (0 = mute) and applies immediately if playing.
    func setMusicVolume(_ volume: Float) {
        let v = max(0, min(1, volume))
        musicVolume = v
        queue.async { [weak self] in
            guard let self else { return }
            self.setupPlayer()
            self.player?.volume = v
            if v <= 0 {
                self.player?.stop()
            } else if self.isMusicEnabled {
                if self.player?.isPlaying != true {
                    self.player?.play()
                }
            } else {
                // The slider is now the single source of truth. If the user raises volume above 0,
                // we should auto-enable music even if an old toggle previously disabled it.
                self.isMusicEnabled = true
                if self.player?.isPlaying != true {
                    self.player?.play()
                }
            }
        }
    }

    /// Updates the persisted music preference and starts or stops playback accordingly.
    /// - Parameter enabled: true to turn music on, false to turn it off.
    func toggleMusic(enabled: Bool) {
        isMusicEnabled = enabled
        if enabled {
            playMusic()
        } else {
            stopMusic()
        }
    }
}
