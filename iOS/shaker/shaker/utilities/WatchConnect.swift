//
//  WatchConnect.swift
//  shaker
//
//  Created by Stan Miasnikov on 1/15/22.
//  Copyright © 2022 PhatWare Corp. All rights reserved.
//

import Foundation
import WatchConnectivity

#if _WATCH_KIT

import WatchKit

// this runs on the watch

@objc class WatchConnect: NSObject
{
    let session = WCSession.default
    var database: CoctailsDatabase

    @objc init(database : CoctailsDatabase)
    {
        self.database = database
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?)
    {
        /* The following trySendingMessageToPhone sometimews fails with
            Error Domain=WCErrorDomain Code=7007 or 7017 "WatchConnectivity session on paired device is not reachable."
            In this case, the transfer is retried a number of times.
         */
        let maxNrRetries = 3
        var availableRetries = maxNrRetries

        func trySendingMessageToPhone(_ message: [String: Any])
        {
            self.session.sendMessage(message, replyHandler: replyHandler, errorHandler: { error in

                print("sending message to watch failed: error: \(error)")
                let nsError = error as NSError
                if nsError.domain == "WCErrorDomain" && (nsError.code == 7007 || nsError.code == 7017) && availableRetries > 0 {
                    availableRetries = availableRetries - 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                        trySendingMessageToPhone(message)
                    })
                }
                else {
                   errorHandler?(error)
                }
            })
        } // trySendingMessageToPhone
        trySendingMessageToPhone(message)
    } // sendMessage

    @objc func sendMessage(message : [String:Any])
    {
        self.sendMessage(message) { reply in
            // TODO: handle reply
            if reply["event"] as? String == kShakerSyncDatabase {
                if let rids = reply["unlocked"] as? [Int64] {
                    for rid in rids {
                        // make all recepies that are unlocked
                        self.database.getRecipe(rid, noImage: true)
                    }
                }
            }
            
        } errorHandler: { error in
            NSLog("sendMessage error: %@", error.localizedDescription)
        }
    }
}

extension WatchConnect: WCSessionDelegate
{
  
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    {
        if let err = error {
            NSLog("activationDidCompleteWith error: %@", err.localizedDescription)
        }
        else {
            self.sendMessage(message: ["event" : kShakerSyncDatabase as Any])
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void)
    {
        NSLog("didReceiveMessageData")
    }
        
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void)
    {
        NSLog("didReceiveMessage: %@", message)

        if let event = message["event"] as? String, let recordid = message["recordid"] as? Int64 {
            switch event {
            case kShakerRecordChanged :
                self.database.getRecipe(recordid, noImage: true)

            case kShakerRecipeUnlocked :
                if let recordid = message["recordid"] as? Int64 {
                    self.database.getRecipe(recordid, noImage: true)
                }
                
            case kShakerSyncDatabase :
                // TODO: workd only from watch to phone on sym, need to test on device
                let arr = self.database.getUnlockedRecordList(true, filter: nil, group: nil, sort: "name ASC")[-1] ?? []
                // ??? self.sendMessage(message: ["event" : kShakerSyncDatabase, "unlocked" : arr])
                replyHandler(["event" : kShakerSyncDatabase, "unlocked" : arr])
                return

            default :
                break
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "messageReceived"), object: nil)
        }
        replyHandler(message)
    }
}

#else

// this runs on the phone

@objc class WatchConnect : NSObject
{
    var session: WCSession?
    var database: CoctailsDatabase
    
    @objc init(database : CoctailsDatabase)
    {
        self.database = database
        super.init()
        self.configureWatchKitSesstion()
    }
    
    fileprivate func configureWatchKitSesstion()
    {
        if WCSession.isSupported() {//4.1
            session = WCSession.default//4.2
            session?.delegate = self//4.3
            session?.activate()//4.4
        }
    }
    
    func sendMessage(_ session : WCSession, message: [String: Any], replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?)
    {
        /* The following trySendingMessageToPhone sometimews fails with
         Error Domain=WCErrorDomain Code=7007 or 7017 "WatchConnectivity session on paired device is not reachable."
         In this case, the transfer is retried a number of times.
         */
        let maxNrRetries = 3
        var availableRetries = maxNrRetries
        
        func trySendingMessageToPhone(_ message: [String: Any])
        {
            session.sendMessage(message, replyHandler: replyHandler, errorHandler: { error in
                
                print("sending message to watch failed: error: \(error)")
                let nsError = error as NSError
                if nsError.domain == "WCErrorDomain" && (nsError.code == 7007 || nsError.code == 7017) && availableRetries > 0 {
                    availableRetries = availableRetries - 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                        trySendingMessageToPhone(message)
                    })
                }
                else {
                    errorHandler?(error)
                }
            })
        } // trySendingMessageToPhone
        trySendingMessageToPhone(message)
    } // sendMessage
    
    
    @objc func sendMessage(message : [String:Any])
    {
        if let validSession = self.session, validSession.isReachable {
            self.sendMessage(validSession, message: message) { reply in
                // TODO: handle reply
            } errorHandler: { error in
                NSLog("sendMessage error: %@", error.localizedDescription)
            }
        }
    }
}

// WCSession delegate functions
extension WatchConnect: WCSessionDelegate
{
    func sessionDidBecomeInactive(_ session: WCSession)
    {
        NSLog("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession)
    {
        NSLog("sessionDidDeactivate")
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    {
        if let err = error {
            NSLog("activationDidCompleteWith error: %@", err.localizedDescription)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession)
    {
        NSLog("sessionReachabilityDidChange")
    }
    

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void)
    {
        // TODO: received message:
        NSLog("didReceiveMessage: %@", message)
        
        if let event = message["event"] as? String  {
            switch event {
            case kShakerRecordChanged :
                break

            case kShakerRecipeUnlocked :
                if let recordid = message["recordid"] as? Int64 {
                    self.database.getRecipe(recordid, noImage: true)
                }
                
            case kShakerSyncDatabase :
                // TODO: workd only from watch to phone on sym, need to test on device
                let arr = self.database.getUnlockedRecordList(true, filter: nil, sort: "name ASC", group: nil)[-1] ?? []
                // ??? self.sendMessage(message: ["event" : kShakerSyncDatabase, "unlocked" : arr])
                replyHandler(["event" : kShakerSyncDatabase, "unlocked" : arr])
                return

            default :
                break
            }
        }
        replyHandler(message)
    }
}

#endif // TARGET_OS_WATCH
