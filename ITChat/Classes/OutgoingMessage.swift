//
//  OutgoingMessage.swift
//  ITChat
//
//  Created by NeilPhung on 8/6/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import Foundation


class OutgoingMessage {
    
    let messageDictionary: NSMutableDictionary
    
    //MARK: - Initializers
    
    //text message
    
    init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }

        
        //MARK: SendMessage
        
        func sendMessage(chatRoomId: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
            
            let messageId = UUID().uuidString
            messageDictionary[kMESSAGEID] = messageId
            
            for memberId in memberIds {
                reference(.Message).document(memberId).collection(chatRoomId).document(messageId).setData(messageDictionary as! [String : Any])
            }
            
//            updateRecents(chatRoomId: chatRoomID, lastMessage: messageDictionary[kMESSAGE] as! String)
//
//            let pushText = "[\(messageDictionary[kTYPE] as! String) message]"
//
//            sendPushNotification(memberToPush: membersToPush, message: pushText)
        }
        
        //update recent chat
        
        //send push notifications
    }
    

