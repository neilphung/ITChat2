//
//  ChatViewController.swift
//  ITChat
//
//  Created by NeilPhung on 8/5/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore

class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var isGroup: Bool?
    var group: NSDictionary?
    var withUsers: [FirebaseUser] = []
    
    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    var typingCounter = 0
    
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    
    var initialLoadComplete = false
    
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    
    //MARK: CustomHeaders
    
    let leftBarButtonView: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    let avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    let titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        
        return title
    }()
    let subTitleLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont(name: subTitle.font.fontName, size: 10)
        
        return subTitle
    }()
    
//    override func viewWillAppear(_ animated: Bool) {
//        clearRecentCounter(chatRoomId: chatRoomId)
//    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        clearRecentCounter(chatRoomId: chatRoomId)
//    }
    
    //fix for Iphone x
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    //end of iphone x fix
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTypingObserver()
        
        loadUserDefaults()
        
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
        navigationItem.largeTitleDisplayMode = .never
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        
        if isGroup! {
            getCurrentGroup(withId: chatRoomId)
        }
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        jsqAvatarDictionary = [ : ]
        
        
        setCustomTitle()
        
        
        loadMessages()
        
        self.senderId = FirebaseUser.currentId()
        self.senderDisplayName = FirebaseUser.currentUser()!.firstname
        
        
        //fix for Ipgone x
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        constraint.priority = UILayoutPriority(rawValue: 1000)
        
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        //end of iphone x fix
        
        
        //custom send button
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        
    }
    
    
    //MARK: JSQMessages DataSource functions
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        //set text color
        if data.senderId == FirebaseUser.currentId() {
            cell.textView?.textColor = .white
        } else {
            cell.textView?.textColor = .black
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FirebaseUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]
            
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item % 3 == 0 {
            
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objectMessages[indexPath.row]
        
        let status: NSAttributedString!
        
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
            
        default:
            status = NSAttributedString(string: "✔︎")
        }
        
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
            return NSAttributedString(string: "")
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FirebaseUser.currentId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.row]
        
        var avatar: JSQMessageAvatarImageDataSource
        
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }
        
        return avatar
    }
    
    
    //MARK: JSQMessages Delegate functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        
        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            camera.PresentMultyCamera(target: self, canEdit: false)
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            
            if self.haveAccessToUserLocation() {
                self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        
        //for iPad not to crash
        if ( UI_USER_INTERFACE_IDIOM() == .pad )
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        
        if text != "" {
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
        } else {
            
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        self.loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            
            self.present(browser!, animated: true, completion: nil)
            
        case kLOCATION:
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
            
            mapView.location = mediaItem.location
            
            self.navigationController?.pushViewController(mapView, animated: true)
            
        case kVIDEO:
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! VideoMessage
            
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviewPlayer = AVPlayerViewController()
            
            let session = AVAudioSession.sharedInstance()
            
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviewPlayer.player = player
            
            self.present(moviewPlayer, animated: true) {
                moviewPlayer.player!.play()
            }
            
        default:
            print("unkown mess tapped")
            
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
        let senderId = messages[indexPath.row].senderId
        var selectedUser: FirebaseUser?
        
        if senderId == FirebaseUser.currentId() {
            selectedUser = FirebaseUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderId {
                    selectedUser = user
                }
            }
        }
        
        presentUserProfile(forUser: selectedUser!)
    }
    
    //for multimedia messages delete option
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:" {
                return true
            } else {
                return false
            }
        } else {
            if action.description == "delete:" || action.description == "copy:" {
                return true
            } else {
                return false
            }
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        
        //delete message from firebase
        OutgoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)
    }
    
    
    
    //MARK: Send Messages
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        
        var outgoingMessage: OutgoingMessage?
        let currentUser = FirebaseUser.currentUser()!
        
        //text message
        if let text = text {
            
            let text = kMESSAGE
//            let ecryptedText = Encryption.encryptText(chatRoomId: chatRoomId, message: text)
            
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        //picture message
        
        if let pic = picture {
            
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                
                if imageLink != nil {
                   let text = kPICTURE
//                    let ecryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kPICTURE)]")
                    
                    outgoingMessage = OutgoingMessage(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
                
            }
            return
        }
        
        //send video
        
        if let video = video {
            
            let videoData = NSData(contentsOfFile: video.path!)
            
            let dataThumbnail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                
                if videoLink != nil {
                    let text = kVIDEO
//                    let ecryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kVIDEO)]")
                    
                    outgoingMessage = OutgoingMessage(message: text, video: videoLink!, thumbNail: dataThumbnail! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                    
                }
            }
            return
        }
        
        
        //send audio
        
        if let audioPath = audio {
            
            uploadAudio(autioPath: audioPath, chatRoomId: chatRoomId, view: (self.navigationController?.view)!) { (audioLink) in
                
                if audioLink != nil {
                    let text = kAUDIO
//                    let ecryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kAUDIO)]")
                    
                    
                    outgoingMessage = OutgoingMessage(message: text, audio: audioLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        //send location message
        if location != nil {
            
            let lat: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
            let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
            
            let text = kLOCATION
//            let ecryptedText = Encryption.encryptText(chatRoomId: chatRoomId, message: "[\(kLOCATION)]")
            
            outgoingMessage = OutgoingMessage(message: text, latitude: lat, longitude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)
        }
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush)
    }
    
    
    
    //MARK: LoadMessages
    
    func loadMessages() {
        
        //to update message status
        updatedChatListener = reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                
                snapshot.documentChanges.forEach({ (diff) in
                    
                    if diff.type == .modified {
                        
                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }
                })
            }
        })
        
        // get last 11 messages
        reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {
                self.initialLoadComplete = true
                self.listenForNewChats()
                return
            }
            
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            //remove bad messages
            self.loadedMessages = self.removeBadMessages(allMessages: sorted)
            
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            
            self.initialLoadComplete = true
            
            self.getPictureMessages()
            
            self.getOldMessagesInBackground()
            self.listenForNewChats()
        }
        
    }
    
    func listenForNewChats() {
        
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        
        newChatListener = reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                
                for diff in snapshot.documentChanges {
                    
                    if (diff.type == .added) {
                        
                        let item = diff.document.data() as NSDictionary
                        
                        if let type = item[kTYPE] {
                            
                            if self.legitTypes.contains(type as! String) {
                                
                                //this is for picture messages
                                if type as! String == kPICTURE {
                                    self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                                }
                                
                                if self.insertInitialLoadMessages(messageDictionary: item) {
                                    
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                
                                self.finishReceivingMessage()
                            }
                        }
                        
                    }
                }
                
            }
            
        })
    }
    
    func getOldMessagesInBackground() {
        
        if loadedMessages.count > 10 {
            
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                
                self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
                
                self.getPictureMessages()
                
                
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    
    //MARK: InsertMessages
    
    func insertMessages() {
        
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in minMessageNumber ..< maxMessageNumber {
            let messageDictionary = loadedMessages[i]
            
            insertInitialLoadMessages(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        if (messageDictionary[kSENDERID] as! String) != FirebaseUser.currentId() {
            
            OutgoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
        }
        
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    func updateMessage(messageDictionary: NSDictionary) {
        
        for index in 0 ..< objectMessages.count {
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessages[index] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
    }
    
    
    //MARK: LoadMoreMessages
    
    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        
        if loadOld {
            maxMessageNumber = minNumber - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed() {
            
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertNewMessage(messageDictionary: NSDictionary) {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    
    //MARK: IBActions
    @objc func backAction() {
        
//        clearRecentCounter(chatRoomId: chatRoomId)
        removeListeners()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func infoButtonPressed() {

        let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "picturesView") as! PicturesCollectionViewController

        mediaVC.allImageLinks = allPictureMessages

        self.navigationController?.pushViewController(mediaVC, animated: true)
    }
    
//    @objc func showGroup() {
//
//        let groupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupViewController
//
//        groupVC.group = group!
//        self.navigationController?.pushViewController(groupVC, animated: true)
//    }
    
    @objc func showUserProfile() {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func presentUserProfile(forUser: FirebaseUser) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = forUser
        self.navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
    //MARK: Typing Indicator
    
    func createTypingObserver() {
        
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                
                for data in snapshot.data()! {
                    if data.key != FirebaseUser.currentId() {
                        
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                    }
                }
            } else {
                reference(.Typing).document(self.chatRoomId).setData([FirebaseUser.currentId() : false])
            }
            
        })
        
    }
    
    func typingCounterStart() {
        
        typingCounter += 1
        
        typingCounterSave(typing: true)
        
        self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingCounterStop() {
        typingCounter -= 1
        
        if typingCounter == 0 {
            typingCounterSave(typing: false)
        }
    }
    
    func typingCounterSave(typing: Bool) {
        
        reference(.Typing).document(chatRoomId).updateData([FirebaseUser.currentId() : typing])
    }
    
    //MARK: UITextViewDelegate
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        typingCounterStart()
        return true
    }
    
    
    
    //MARK: CustomSendButton
    
    override func textViewDidChange(_ textView: UITextView) {
        
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
        
    }
    
    func updateSendButton(isSend: Bool) {
        
        if isSend {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
        
    }
    
    //MARK: IQAudioDelegate
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        
        controller.dismiss(animated: true, completion: nil)
        self.sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UpdateUI
    
    func setCustomTitle() {
        
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
//        if isGroup! {
//            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
//        } else {
//            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
//        }
        
        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            
            self.withUsers = withUsers
            self.getAvatarImages()
            if !self.isGroup! {
                self.setUIForSingleChat()
            }
        }
        
    }
    
    func setUIForSingleChat() {
        
        let withUser = withUsers.first!
        
        imageFromData(pictureData: withUser.avatar) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        
        titleLabel.text = withUser.fullname
        
        if withUser.isOnline {
            subTitleLabel.text = "Online"
        } else {
            subTitleLabel.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    func setUIForGroupChat() {
        
        imageFromData(pictureData: (group![kAVATAR] as! String)) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        
        titleLabel.text = titleName
        subTitleLabel.text = ""
    }
    
    
    //MARK: UIImagePickerController delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: GetAvatars
    
    func getAvatarImages() {
        
        if showAvatars {
            
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            //get current user avatar
            avatarImageFrom(FirebaseUser: FirebaseUser.currentUser()!)
            
            for user in withUsers {
                avatarImageFrom(FirebaseUser: user)
            }
            
        }
    }
    
    func avatarImageFrom(FirebaseUser: FirebaseUser) {
        
        if FirebaseUser.avatar != "" {
            
            dataImageFromString(pictureString: FirebaseUser.avatar) { (imageData) in
                
                if imageData == nil {
                    return
                }
                
                
                if self.avatarImageDictionary != nil {
                    //update avatar if we had one
                    self.avatarImageDictionary!.removeObject(forKey: FirebaseUser.objectId)
                    self.avatarImageDictionary!.setObject(imageData!, forKey: FirebaseUser.objectId as NSCopying)
                } else {
                    self.avatarImageDictionary = [FirebaseUser.objectId : imageData!]
                }
                
                self.createJSQAvatars(avatarDictionary: self.avatarImageDictionary)
            }
        }
        
    }
    
    func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
        
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        if avatarDictionary != nil {
            
            for userId in memberIds {
                
                if let avatarImageData = avatarDictionary![userId] {
                    
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 70)
                    
                    self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: userId)
                } else {
                    self.jsqAvatarDictionary!.setValue(defaultAvatar, forKey: userId)
                }
                
            }
            
            self.collectionView.reloadData()
        }
    }
    
    //MARK: Location access
    
    func haveAccessToUserLocation() -> Bool {
        if appDelegate.locationManager != nil {
            return true
        } else {
            ProgressHUD.showError("Please give access tp loacation in Settings.")
            return false
        }
    }
    
    
    //MARK: Helper functions
    
    func loadUserDefaults() {
        
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatars, forKey: kSHOWAVATAR)
            
            userDefaults.synchronize()
        }
        
        showAvatars = userDefaults.bool(forKey: kSHOWAVATAR)
        checkForBackgroundImage()
    }
    
    func checkForBackgroundImage() {
        
        if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
            self.collectionView.backgroundColor = .clear
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
            imageView.image = UIImage(named: userDefaults.object(forKey: kBACKGROUBNDIMAGE) as! String)!
            imageView.contentMode = .scaleAspectFill
            
            self.view.insertSubview(imageView, at: 0)
        }
    }
    
    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
    }
    
    func getPictureMessages() {
        
        allPictureMessages = []
        
        for message in loadedMessages {
            
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    func readTimeFrom(dateString: String) -> String {
        
        let date = dateFormatter().date(from: dateString)
        
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        
        return currentDateFormat.string(from: date!)
        
    }
    
    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        
        var tempMessages = allMessages
        
        for message in tempMessages {
            
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String) {
                    
                    //remove the message
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
            } else {
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        
        return tempMessages
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        
        if FirebaseUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
        
    }
    
    func removeListeners() {
        
        if typingListener != nil {
            typingListener!.remove()
        }
        if newChatListener != nil {
            newChatListener!.remove()
        }
        if updatedChatListener != nil {
            updatedChatListener!.remove()
        }
    }
    
    func getCurrentGroup(withId: String) {
        
        reference(.Group).document(withId).getDocument { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                self.group = snapshot.data() as! NSDictionary
                self.setUIForGroupChat()
            }
        }
    }
    
}

