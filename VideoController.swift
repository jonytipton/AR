//
//  VideoController.swift
//  Created by Jonathan Tipton on 4/16/20.
//

import UIKit
import AVKit
import AVFoundation

class VideoController: UIViewController {
  
    var player :AVPlayer?
  
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        let destination = segue.destination as! AVPlayerViewController
      let url = Bundle.main.url(forResource: "tutorial", withExtension: ".mp4")
        if let movieURL = url {
            destination.player = AVPlayer(url:movieURL)
            player = destination.player
            player?.play()
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPicutreStopWithCompletionHandler completionHandler: @escaping(Bool)->Void) {
        let currentViewController = navigationController?.visibleViewController
        if currentViewController != playerViewController {
            if let topViewController = navigationController?.topViewController {
                topViewController.present(playerViewController, animated:true, completion: {();
                    completionHandler(true)
                })
            }
        }
      playerViewController.exitsFullScreenWhenPlaybackEnds = true;
      }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
  
  override func viewDidAppear(_ animated: Bool) {
    NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name:
    NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
  }
  
  
  @objc func videoDidEnd(notification: NSNotification) {
    print("video ended")
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let newViewController = storyboard.instantiateViewController(identifier: "ActivityCustomization")
    self.navigationController?.pushViewController(newViewController, animated: true)
  }
  
  
}

