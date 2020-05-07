import UIKit
import SceneKit
import ARKit
import AVKit
import AVFoundation

enum ContentType: Int {
    case pig
}

class ViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var playPauseLabel: UILabel!
    @IBOutlet weak var redoLabel: UILabel!
    @IBOutlet weak var tutImage: UIImageView!
    @IBAction func screenshotPressed(_ sender: Any) {
        screenshot(of: sceneView)
    }
    
    let backgroundMusic = Bundle.main.path(forResource: "backgroundMusic", ofType: ".mp3")
    var timerGoing: Bool = false
    var appTimer: Timer?
    var timerCount = 10
    var nextRound: Bool = true
    var currentRound = 0
    var audioPlayer = AVAudioPlayer()
    
    @IBAction func settingsPressed(_ sender: Any) {
        print("Need to stop timer. Settings PRESSED")
        timerGoing = false
        playPauseLabel.text = "Start"
    }
    @IBAction func playPauseButton(_ sender: Any) {
        if (playPauseLabel.text == "Start") {
            playPauseLabel.text = "Stop"
            print("Need to START timer. Start PRESSED")
            timerGoing = true
        }
        else {
            playPauseLabel.text = "Start"
            print("Need to STOP timer. Stop PRESSED")
            timerGoing = false
        }
        
        if (messageLabel.text == "COMPLETE! Next Round?") {
            timerGoing = true
            timerCount = 10
        }
        if (!tutImage.isHidden) {
            tutImage.isHidden = true
        }
    }
    @IBAction func redoPressed(_ sender: Any) {
        if (redoLabel.text == "?") {
            print("Need to RESET timer. Redo PRESSED")
            redoLabel.text = "Redo"
            timerGoing = false
            timerCount = 10
            playPauseLabel.text = "Start"
            DispatchQueue.main.async {
                self.tutImage.isHidden = false
            }
        }
        else {
            redoLabel.text = "?"
        }
    }
    var session: ARSession {
        return sceneView.session
    }
    
    var contentTypeSelected: ContentType = .pig
    var anchorNode: SCNNode?
    var pig: Pig?
    
    // MARK: - View Management
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        setupScene()
        createFaceGeometry()
        appTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimer), userInfo: nil, repeats: true)
        tutImage.isHidden = true
        let backgroundMusicURL = URL(fileReferenceLiteralResourceName: "backgroundMusic.mp3")
        do {
            audioPlayer = try AVAudioPlayer.init(contentsOf: backgroundMusicURL)
            audioPlayer.play()
            print("Play audio")
        }
        catch {
            print(error)
        }
    }
    
    @objc func runTimer() {
        if (timerGoing) {
            timerCount -= 1
        }
        if (timerCount == 0) {
            timerGoing = false
        }
        print("Timer at: ", timerCount)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}



// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    // Tag: SceneKit Renderer
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 1
        guard let estimate = session.currentFrame?.lightEstimate else {
            return
        }
        // 2
        let intensity = estimate.ambientIntensity / 1000.0
        sceneView.scene.lightingEnvironment.intensity = intensity
        // 3
        //let intensityStr = String(format: "%.2f", intensity)
        //let sceneLighting = String(format: "%.2f",
        //                           sceneView.scene.lightingEnvironment.intensity)
        // 4
        //print("Intensity: \(intensityStr) - \(sceneLighting)")
    }
    
    // Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        anchorNode = node
        setupFaceNodeContent()
        DispatchQueue.main.async {
            self.tutImage.isHidden = false
        }
    }
    
    // Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {return}
        if (timerCount == 0) {
            timerGoing = false
            currentRound += 1
            print("New Round!", currentRound)
            DispatchQueue.main.async {
                self.tutImage.isHidden = false
            }
        }
        if (timerGoing) {
            updateMessage(text: "Time Remaining: \(timerCount)")
        }
        else if (!(timerCount <= 0)) {
            updateMessage(text: "Ready to brush?")
        }
        else if (nextRound) {
            updateMessage(text: "COMPLETE! Next Round?")
            DispatchQueue.main.async {
                self.playPauseLabel.text = "Start"
            }
        }
        else {
            updateMessage(text: "ALL DONE!")
            //FUNCTION TO CLOSE AR/CHANGE VIEW
            //play award animation?
        }
        pig?.update(withFaceAnchor: faceAnchor)
        if (timerCount == 0) {
            timerCount = 10
        }
        
        DispatchQueue.main.async {
            if (self.currentRound == 0) {
                self.tutImage.image = UIImage(named: "brushBottom.png")
            }
            else if (self.currentRound == 1) {
                self.tutImage.image = UIImage(named: "brushTop.png")
            }
            else if (self.currentRound == 2) {
                self.tutImage.image = UIImage(named: "brushCircle.png")
            }
        }
        if (currentRound == 3) {
            goToReward()
        }
    }
    
    func goToReward() {
        print("AR ended")
        DispatchQueue.main.async {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyboard.instantiateViewController(identifier: "Winner")
            self.navigationController?.pushViewController(newViewController, animated: true)
            self.appTimer?.invalidate()
        }
    }
    
    
    // Tag: ARSession Handling
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("** didFailWithError")
        updateMessage(text: "Session failed.")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("** sessionWasInterrupted")
        updateMessage(text: "Session interrupted.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("** sessionInterruptionEnded")
        updateMessage(text: "Session interruption ended.")
    }
}


// MARK: - Private methods

private extension ViewController {
    // Tag: SceneKit Setup
    func setupScene() {
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        // Setup environment
        sceneView.automaticallyUpdatesLighting = true /* default setting */
        sceneView.autoenablesDefaultLighting = false /* default setting */
        sceneView.scene.lightingEnvironment.intensity = 1.0 /* default setting */
    }
    
    // Tag: ARFaceTrackingConfiguration
    func resetTracking() {
        // 1
        guard ARFaceTrackingConfiguration.isSupported else {
            updateMessage(text: "This device does not support Face Tracking.")
            return
        }
        // 2
        updateMessage(text: "Looking for a face.")
        // 3
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true /* default setting */
        configuration.providesAudioData = false /* default setting */
        // New options available in iOS 13+
        if #available(iOS 13.0, *) {
            configuration.isWorldTrackingEnabled = false /* default setting */
            configuration.maximumNumberOfTrackedFaces = 1 /* default setting */
        }
        // 4
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // Tag: CreateARSCNFaceGeometry
    func createFaceGeometry() {
        print("Creating face geometry.")
        let device = sceneView.device!
        let pigGeometry = ARSCNFaceGeometry(device: device)!
        pig = Pig(geometry: pigGeometry)
    }
    
    // Tag: Setup Face Content Nodes
    func setupFaceNodeContent() {
        guard let node = anchorNode else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
        node.addChildNode(pig!)
    }
    
    // Tag: Update UI
    func updateMessage(text: String) {
        DispatchQueue.main.async {
            self.messageLabel.text = text
        }
    }
    func screenshot(of view: ARSCNView) {
        let renderedImage = sceneView.snapshot()
        
        UIImageWriteToSavedPhotosAlbum(renderedImage, self, #selector(imageWasSaved), nil)
    }
    
    @objc func imageWasSaved(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        print("image saved")
    }
    
}
