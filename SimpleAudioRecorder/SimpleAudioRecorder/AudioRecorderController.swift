//
//  ViewController.swift
//  AudioRecorder
//
//  Created by Paul Solt on 10/1/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AudioRecorderController: UIViewController {
    
    // MARK: Playback
    var audioPlayer: AVAudioPlayer?
    
    // MARK: Recording
    var audioRecorder: AVAudioRecorder?
    var recordURL: URL?
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
	
	private lazy var timeFormatter: DateComponentsFormatter = {
		let formatting = DateComponentsFormatter()
		formatting.unitsStyle = .positional // 00:00  mm:ss
		// NOTE: DateComponentFormatter is good for minutes/hours/seconds
		// DateComponentsFormatter not good for milliseconds, use DateFormatter instead)
		formatting.zeroFormattingBehavior = .pad
		formatting.allowedUnits = [.minute, .second]
		return formatting
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()


        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
        
        loadAudio()
        updateViews()
	}

    private func loadAudio() {
        // piano.mp3
        let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
        
        // create the player
        audioPlayer = try! AVAudioPlayer(contentsOf: songURL)
        audioPlayer?.delegate = self
    }
    

    @IBAction func playButtonPressed(_ sender: Any) {
        playPause()
    }
    
    // Timer
    var timer: Timer?
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    // Play back
    func play() {
        audioPlayer?.play()
        startTimer()
        updateViews()
    }
    
    func pause() {
        audioPlayer?.pause()
        cancelTimer()
        updateViews()
    }
    
    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    private func startTimer() {
        cancelTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer(timer:)), userInfo: nil, repeats: true)
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func updateTimer(timer: Timer) {
        updateViews()
    }
    
    /// TODO: Update the UI for the playback
    private func updateViews() {
        // Play Pause button
        let playButtonTItle = isPlaying ? "Pause" : "Play"
        playButton.setTitle(playButtonTItle, for: .normal)
        
        // audio time
        let elapsedTime = audioPlayer?.currentTime ?? 0
        timeLabel.text = timeFormatter.string(from: elapsedTime)
        
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        timeSlider.value = Float(elapsedTime)
        
        let recordButtonTitle = isRecording ? "Stop Recoding" : "Record"
        recordButton.setTitle(recordButtonTitle, for: .normal)
    }
    
    // MARK: Recoding
    @IBAction func recordButtonPressed(_ sender: Any) {
        recordToggle()
    }
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    func record() {
        // Path to save in the documents direcgtory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Filename (ISO8601 format for time) .caf extension (core audio file)
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
        
        // 2019-12-03T10:42:35-08:00.caf
        let file = documentsDirectory.appendingPathComponent(name).appendingPathExtension("caf")
        
        print("Record URL: \(file)")
        // Audio Quality 44.1KHz
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        
        // Start a recoding
        audioRecorder = try! AVAudioRecorder(url: file, format: format)
        recordURL = file
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func recordToggle() {
        if isRecording {
            stopRecording()
        } else {
            record()
        }
    }
    
    // TODO; Know when the recoding finished, sothat we can play it back
}

extension AudioRecorderController: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio playback error: \(error)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()   // TODO: is this on the main thread?
        // TODO: Cancel timer?
    }
}

extension AudioRecorderController: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio record error: \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag == true {
            // if let recordURL = recordURL    works as well
            audioPlayer = try! AVAudioPlayer(contentsOf: recorder.url) // catch errors
        }
    }
}
