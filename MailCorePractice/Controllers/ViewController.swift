//
//  ViewController.swift
//  MailCorePractice
//
//  Created by Koh Jia Rong on 2019/2/1.
//  Copyright © 2019 Koh Jia Rong. All rights reserved.
//

import UIKit
import GTMAppAuth
import AppAuth

class ViewController: UITableViewController {

//    let clientID = "382696408917-76dm92efvi9nhmqjnv3fmu56nv71l6j0.apps.googleusercontent.com"
//    let clientSecret = "HF7wjjBXHojp6W774qXLZBSz"
//
    let kIssuer = "https://accounts.google.com"
    let kClientID = "382696408917-r139aava2dj6jlgluatmoqnc019vplo8.apps.googleusercontent.com"
    let kRedirectURI = "com.googleusercontent.apps.382696408917-r139aava2dj6jlgluatmoqnc019vplo8:/oauthredirect"
    let kExampleAuthorizerKey = "googleOAuthCodingKey"
    
    var messages = [Message]()
    
    let edisonAccount = Account(username: "jiarongtest@gmail.com", password: "S9048009Z", hostname: "smtp.gmail.com", port: 465)
    let account126 = Account(username: "jiarongkoh@126.com", password: "edison123", hostname: "smtp.126.com", port: 465)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sent", style: .plain, target: self, action: #selector(alertControllerForSendEmail))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Authenticate", style: .plain, target: self, action: #selector(authenticateGmailIfNeeded))
        
        setupTableView()
//        fetchEmailsFrom126()

//        authenticateGmailIfNeeded()


    }


    
    @objc func authenticateGmailIfNeeded() {
        GmailHelper.shared.doEmailLoginIfRequired(viewController: self) {
            if
                let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: self.kExampleAuthorizerKey),
                let accessToken = authorization.authState.lastTokenResponse?.accessToken {
                self.fetchEmailsFromGmail(accessToken: accessToken)
            }
        }
    }
    
    @objc func alertControllerForSendEmail() {
        let alert = UIAlertController(title: "Send email", message: nil, preferredStyle: .actionSheet)
        let gmailAction = UIAlertAction(title: "Gmail", style: .default) { (_) in
            self.sendEmail(account: self.edisonAccount)
        }
        let email126Action = UIAlertAction(title: "126", style: .default) { (_) in
            self.sendEmail(account: self.account126)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(gmailAction)
        alert.addAction(email126Action)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    var host = "210.12.48.100"
    
    func fetchEmailsFromGmail(accessToken: String) {
        print("Fetching emails from Gmail...")
        let session = MCOIMAPSession()
        session.hostname = "imap.gmail.com"
        session.port = 993
        session.username = "jiarongtest@gmail.com"
//        session.password = "S9048009Z"
        session.authType = .xoAuth2
        session.connectionType = .TLS
        session.oAuth2Token = accessToken
        session.dispatchQueue = DispatchQueue.global()

        let requestKind: MCOIMAPMessagesRequestKind = [.headers, .flags]
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        
        session.connectionLogger = {(connectionID, type, data) in
            if let data = data {
                if let string = String(data: data, encoding: String.Encoding.utf8){
                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        
        downloadEmails(session: session, folder: folder, requestKind: requestKind, uids: uids)
    }
    
    func fetchEmailsFrom126() {
        print("Fetching emails from 126...")

        let session = MCOIMAPSession()
        session.hostname = "imap.126.com"
        session.port = 993
        session.username = "jiarongkoh@126.com"
        session.password = "edison123"
        session.connectionType = .TLS
        session.dispatchQueue = DispatchQueue.global()
        
        let requestKind: MCOIMAPMessagesRequestKind = [.headers, .flags]
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        
//        fetchFolders(session: session)

        downloadEmails(session: session, folder: folder, requestKind: requestKind, uids: uids)
    }
    
    func sendEmail(account: Account) {
        print("Sending message...")
        
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = account.hostname
        smtpSession.port = account.port ?? 465
        smtpSession.username = account.username
        smtpSession.password = account.password
        smtpSession.connectionType = .TLS
        
        let builder = MCOMessageBuilder()
        builder.header.from = MCOAddress(displayName: nil, mailbox: account.username)
        
        let newAddress = MCOAddress(displayName: nil, mailbox: account.username)
        builder.header.to = [newAddress]
        
        builder.header.subject = "Attachment test!!"
        builder.textBody = "Weeee from test app"
        
        let image = UIImage(named: "coffeebeans")
        let imageData = image?.jpegData(compressionQuality: 1)
        let attachment = MCOAttachment(data: imageData, filename: "coffee.png")
        builder.addAttachment(attachment)
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data)
        sendOperation?.start({ (error) in
            if let error = error {
                print("Error sending message:", error.localizedDescription)
                return
            }
            
            print("Message sent")
        })
    }
    
    func fetchFolders(session: MCOIMAPSession) {
        let fetchFolderOperation = session.fetchAllFoldersOperation()
        fetchFolderOperation?.start({ (error, folders) in
            if let error = error {
                print("Error fetching folders:", error.localizedDescription)
                return
            }
            
            if let folders = folders, !folders.isEmpty {
                print(folders)
            }
        })
    }
    
    func downloadEmails(session: MCOIMAPSession, folder: String, requestKind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet?) {
        fetchMessagesBody(session: session, folder: folder, requestKind: requestKind, uids: uids) { (messages, error) in
            if let error = error {
                print("Error downloading emails:", error.localizedDescription)
                return
            }
            
            if let messages = messages {
                self.messages = messages.reversed()
                
                DispatchQueue.main.async {
                    NSLog("Finished dowloading emails")
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func fetchMessagesBody(session: MCOIMAPSession, folder: String, requestKind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet?, completion: @escaping (_ messages: [Message]?, _ error: Error?) -> Void) {
        
        let fetchOperation = session.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        
        fetchOperation?.start({ (error, messages, vanishedMessages) in
            completion(nil, error)
            
            if let vanishedMessages = vanishedMessages {
                print(vanishedMessages)
            }
            
            if let messages = messages, !messages.isEmpty {
                var messsageArray = [Message]()
                let downloadGroup = DispatchGroup()
                
                messages.forEach({ (message) in
                    downloadGroup.enter()
                    let op = session.fetchMessageOperation(withFolder: folder, uid: message.uid)
                    op?.start({ (error, data) in
                        if let _ = error {
                            downloadGroup.leave()
                        }
                        
                        if let data = data {
                            let messageParser = MCOMessageParser(data: data)
                            let subject = messageParser?.header.subject
                            let plainBodyText = messageParser?.plainTextBodyRendering()
                            let message = Message(subject: subject, bodyText: plainBodyText)
                            messsageArray.append(message)
                            downloadGroup.leave()
                        }
                    })
                })

                downloadGroup.notify(queue: .global(), execute: {
                    completion(messsageArray, nil)
                })
            }
        })
    }
}
