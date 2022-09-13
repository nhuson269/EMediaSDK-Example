//
//  ConferenceViewController.swift
//  EMediaReferenceApplication
//

import UIKit
import Foundation
import EMediaSDK
import WebRTC

open class ConferenceViewController: UIViewController {
   
    var conferenceClient: ConferenceClient!
    var clientUrl: String!
    var roomId: String!
    var publisherStreamId: String!
    
    @IBOutlet var localView: UIView!
    @IBOutlet var remoteView0: UIView!
    @IBOutlet var remoteView1: UIView!
    @IBOutlet var remoteView2: UIView!
    @IBOutlet var remoteView3: UIView!
        
    var remoteViews:[UIView] = []
    
    private let audioQueue = DispatchQueue(label: "audio")
    
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    
    var viewFree:[Bool] = [true, true, true, true]
    
    var publisherClient: EMediaClient?;
    var playerClients:[EMediaClientConference] = [];
    
    class EMediaClientConference {
        var playerClient: EMediaClient;
        var viewIndex: Int;
        
        init(player: EMediaClient, index: Int) {
            self.playerClient = player;
            self.viewIndex = index
        }
    }
    
    
    
    open override func viewWillAppear(_ animated: Bool)
    {
        remoteViews.append(remoteView0)
        remoteViews.append(remoteView1)
        remoteViews.append(remoteView2)
        remoteViews.append(remoteView3)
        EMediaClient.setDebug(true)
        conferenceClient = ConferenceClient.init(serverURL: self.clientUrl, conferenceClientDelegate: self)
        conferenceClient.joinRoom(roomId: self.roomId, streamId: "")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.publisherClient?.stop()
        for client in playerClients
        {
            client.playerClient.stop();
        }
        conferenceClient.leaveRoom()
    }
    
    public func speakerOn() {
       
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                EMediaClient.printf("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    public func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    
}

extension ConferenceViewController: ConferenceClientDelegate
{
    public func streamIdToPublish(streamId: String) {
        
        Run.onMainThread {
        //
            EMediaClient.printf("stream id to publish \(streamId)")
            
            self.publisherStreamId = streamId;
            self.publisherClient =  EMediaClient.init();
            self.publisherClient?.delegate = self
            self.publisherClient?.setOptions(url: self.clientUrl, streamId: self.publisherStreamId, token: "", mode: EMediaClientMode.publish, enableDataChannel: false)
            
            self.publisherClient?.setLocalView(container: self.localView)
           
            self.publisherClient?.initPeerConnection()
            self.publisherClient?.start()
            
        }
           
    }
       
    public func newStreamsJoined(streams: [String]) {
        
        EMediaClient.printf("Room current capacity: \(playerClients.count)")
        if (playerClients.count == 4) {
            EMediaClient.printf("Room is full")
            return
        }
        Run.onMainThread {
            
        
            for stream in streams
            {
                EMediaClient.printf("stream in the room: \(stream)")
                let playerClient = EMediaClient.init()
                playerClient.delegate = self;
                playerClient.setOptions(url: self.clientUrl, streamId: stream, token: "", mode: EMediaClientMode.play, enableDataChannel: false)
                
                var freeIndex: Int = -1
                for (index,free) in self.viewFree.enumerated() {
                    if (free) {
                        freeIndex = index;
                        self.viewFree[index] = false;
                        break;
                    }
                }
                if (freeIndex == -1) {
                    EMediaClient.printf("Problem in free view index")
                }
                playerClient.setRemoteView(remoteContainer: self.remoteViews[freeIndex])
                playerClient.initPeerConnection()
                playerClient.start()
                self.remoteViews[freeIndex].isHidden = false
                
                let playerConferenceClient = EMediaClientConference.init(player: playerClient, index: freeIndex);
                
                self.playerClients.append(playerConferenceClient)
                
            }
        }
       
           
    }
       
    public func streamsLeaved(streams: [String]) {
        
        Run.onMainThread {
        
            var leavedClientIndex:[Int] = []
            for streamId in streams
            {
                for  (clientIndex,conferenceClient) in self.playerClients.enumerated()
                {
                    if (conferenceClient.playerClient.getStreamId() == streamId) {
                        conferenceClient.playerClient.stop();
                        self.remoteViews[conferenceClient.viewIndex].isHidden = true
                        self.viewFree[conferenceClient.viewIndex] = true
                        leavedClientIndex.append(clientIndex)
                        break;
                    }
                }
            }
            
            for index in leavedClientIndex {
                self.playerClients.remove(at: index);
            }
        }
    }
}

extension ConferenceViewController: EMediaClientDelegate
{
    public func clientDidConnect(_ client: EMediaClient) {
        EMediaClient.printf("Websocket is connected")
    }
    
    public func clientDidDisconnect(_ message: String) {
        
    }
    
    public func clientHasError(_ message: String) {
        
    }
    
    public func remoteStreamStarted(streamId: String) {
        
    }
    
    public func remoteStreamRemoved(streamId: String) {
        
    }
    
    public func localStreamStarted(streamId: String) {
        
    }
    
    public func playStarted(streamId: String) {
        print("play started");
        self.speakerOn();
        
    }
    
    public func playFinished(streamId: String) {
        
    }
    
    public func publishStarted(streamId: String) {
        
    }
    
    public func publishFinished(streamId: String) {
        
    }
    
    public func disconnected(streamId: String) {
        
    }
    
    public func audioSessionDidStartPlayOrRecord(streamId: String) {
        
    }
    
    public func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    public func streamInformation(streamInfo: [StreamInformation]) {
        
    }
    
    
}
