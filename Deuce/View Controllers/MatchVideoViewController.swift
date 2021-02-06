//
//  MatchVideoViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 1/22/21.
//  Copyright © 2021 Austin Conlon. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

protocol MatchVideoViewControllerOutputDelegate: AnyObject {
    func matchVideoViewController(_ controller: MatchVideoViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation)
}

class MatchVideoViewController: UIViewController {
    
    weak var outputDelegate: MatchVideoViewControllerOutputDelegate?
    
    private let matchVideoController = MatchVideoController.shared
    
    // Video file playback management.
    private var videoRenderView: VideoRenderView!
    private var playerItemOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private let videoFileReadingQueue = DispatchQueue(label: "VideoFileReading", qos: .userInteractive)
    private var videoFileBufferOrientation = CGImagePropertyOrientation.up
    private var videoFileFrameDuration = CMTime.invalid
    
    private let trajectoryQueue = DispatchQueue(label: "com.example.Deuce.trajectory", qos: .userInteractive)
    private let trajectoryDetectionMinConfidence: VNConfidence = 0.9
    private lazy var detectTrajectoryRequest: VNDetectTrajectoriesRequest! =
                        VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 15)
    
    private var mutableComposition: AVMutableComposition?

    override func viewDidLoad() {
        super.viewDidLoad()

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    func setupVideoOutputView(_ videoOutputView: UIView) {
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoOutputView)
        NSLayoutConstraint.activate([
            videoOutputView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoOutputView.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func startReading(asset: AVAsset) {
        videoRenderView = VideoRenderView(frame: view.bounds)
        setupVideoOutputView(videoRenderView)
        
        // Set up display link.
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.preferredFramesPerSecond = 0 // Use display's rate
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.current, forMode: .default)
        
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("No video tracks found in AVAsset.")
            return
        }
        
        trim(asset: asset)
        
        guard let mutableComposition = mutableComposition else {
            print("No mutable composition found.")
            return
        }
        
        let playerItem = AVPlayerItem(asset: mutableComposition)
        let player = AVPlayer(playerItem: playerItem)
        let settings = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        playerItem.add(output)
        player.actionAtItemEnd = .pause
        player.play()

        self.displayLink = displayLink
        self.playerItemOutput = output
        self.videoRenderView.player = player
        
        videoFileFrameDuration = track.minFrameDuration
        displayLink.isPaused = false
    }
    
    func trim(asset: AVAsset) {
        var assetVideoTrack: AVAssetTrack?
        var assetAudioTrack: AVAssetTrack?
        
        if asset.tracks(withMediaType: .video).count != 0 {
            assetVideoTrack = asset.tracks(withMediaType: .video)[0]
        }
        
        if asset.tracks(withMediaType: .audio).count != 0 {
            assetAudioTrack = asset.tracks(withMediaType: .audio)[0]
        }
        
        let insertionPoint: CMTime = CMTime.zero
        
        // Trim to half duration.
        let halfDuration: Double = CMTimeGetSeconds(asset.duration)/2.0
        let trimmedDuration: CMTime = CMTimeMakeWithSeconds(halfDuration, preferredTimescale: 1)
        
        if mutableComposition == nil {
            self.mutableComposition = AVMutableComposition()
            
            // Insert half of the time range of the video and audio tracks from the AVAsset.
            if let assetVideoTrack = assetVideoTrack {
                let compositionVideoTrack = self.mutableComposition?.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: trimmedDuration), of: assetVideoTrack, at: insertionPoint)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
            
            if let assetAudioTrack = assetAudioTrack {
                let compositionAudioTrack = self.mutableComposition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: trimmedDuration), of: assetAudioTrack, at: insertionPoint)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        } else {
            // Remove the second half of the existing composition to trim.
            self.mutableComposition?.removeTimeRange(CMTimeRangeMake(start: trimmedDuration, duration: self.mutableComposition!.duration))
        }
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let output = playerItemOutput else {
            return
        }
        
        videoFileReadingQueue.async {
            let nextTimeStamp = displayLink.timestamp + displayLink.duration
            let itemTime = output.itemTime(forHostTime: nextTimeStamp)
            guard output.hasNewPixelBuffer(forItemTime: itemTime) else {
                return
            }
            guard let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else {
                return
            }
            // Create sample buffer from pixel buffer.
            var sampleBuffer: CMSampleBuffer?
            var formatDescription: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
            let duration = self.videoFileFrameDuration
            var timingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: itemTime, decodeTimeStamp: itemTime)
            CMSampleBufferCreateForImageBuffer(allocator: nil,
                                               imageBuffer: pixelBuffer,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: formatDescription!,
                                               sampleTiming: &timingInfo,
                                               sampleBufferOut: &sampleBuffer)
            if let sampleBuffer = sampleBuffer {
                let visionHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: self.videoFileBufferOrientation, options: [:])
                do {
                    try visionHandler.perform([self.detectTrajectoryRequest])
                    if let results = self.detectTrajectoryRequest.results {
                        for path in results where path.confidence > self.trajectoryDetectionMinConfidence {
                            // VNDetectTrajectoriesRequest has returned some trajectory observations.
                            // Process the path only when the confidence is over 90%.
                            
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension MatchVideoViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        matchVideoController.recordedVideoSource = nil
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        matchVideoController.recordedVideoSource = AVAsset(url: url)
        if let video = matchVideoController.recordedVideoSource {
            startReading(asset: video)
            
        }
    }
}
