//
//  Recent.swift
//  ITChat
//
//  Created by NeilPhung on 8/4/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import Foundation


func startPrivateChat(Fuser1 : FirebaseUser, Fuser2 : FirebaseUser) -> String{
    
    let user1 = Fuser1.objectId
    let user2 = Fuser2.objectId
    
    var chatRoomId = ""
    
    let value = user1.compare(user2).rawValue
    
    if value < 0 {
        chatRoomId = user1 + user2
    }
    else {
        chatRoomId = user2 + user2
    }
    
    let members = [user1, user2]
    
    //create recent Chats
    createRecent(members: members, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE, users: [Fuser1, Fuser2], avatarOfGroup: nil)
    
    return chatRoomId
}

func createRecent(members: [String], chatRoomId: String, withUserUserName: String, type: String, users: [FirebaseUser]?, avatarOfGroup: String?){
    
    var tempMembers = members
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currenRecent = recent.data() as NSDictionary
                
                if let currentUserId = currenRecent[kUSERID]{
                    
                    if tempMembers.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
                    }
                }
            }
        }
        
        for userId in tempMembers {
            
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
}

func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserUserName: String, type: String, users: [FirebaseUser]?, avatarOfGroup: String?) {
    
    let localReference = reference(.Recent).document()
    
    let recentId = localReference.documentID
    
    let date = dateFormatter().string(from: Date())
    
    var recent: [String : Any]!
    
    if type == kPRIVATE {
        //private
        
        var withUser: FirebaseUser?
        
        if users != nil && users!.count > 0 {
            if userId == FirebaseUser.currentId() {
                //for current user
                withUser = users?.last
            }else {
                withUser = users?.first
            }
            
        }
        
        recent = [kRECENTID : recentId, kUSERID : userId, kCHATROOMID : chatRoomId, kMEMBERS : members, kMEMBERSTOPUSH : members, kWITHUSERFULLNAME : withUser!.fullname, kWITHUSERUSERID : withUser!.objectId, kLASTMESSAGE : "" , kCOUNTER : 0, kDATE : date, kTYPE : type, kAVATAR: withUser!.avatar ] as [String : Any]
    }
    else {
        //group
        if avatarOfGroup != nil {
            
            recent = [kRECENTID : recentId, kUSERID : userId, kCHATROOMID : chatRoomId, kMEMBERS : members, kMEMBERSTOPUSH : members, kWITHUSERFULLNAME : withUserUserName, kLASTMESSAGE : "", kCOUNTER : 0, kDATE : date, kTYPE : type, kAVATAR : avatarOfGroup!] as [String:Any]
        }
    }
    
    //save recent chat
    localReference.setData(recent)
}


//Restart Chat

func restartRecentChat(recent: NSDictionary) {
    
    if recent[kTYPE] as! String == kPRIVATE {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: FirebaseUser.currentUser()!.firstname, type: kPRIVATE, users: [FirebaseUser.currentUser()!], avatarOfGroup: nil)
    }
    
    if recent[kTYPE] as! String == kGROUP {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: recent[kWITHUSERFULLNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)
    }
}


//Delete recent
func deleteRecentChat(recentChatDictionary: NSDictionary) {
    
    if let recentId = recentChatDictionary[kRECENTID] {
        
        reference(.Recent).document(recentId as! String).delete()
    }
}
