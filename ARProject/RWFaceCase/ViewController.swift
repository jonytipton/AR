/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SceneKit
import ARKit
import AVKit
import AVFoundation

enum ContentType: Int {
  case none
  case mask
  case glasses
  case pig
}

class ViewController: UIViewController {

  // MARK: - Properties

  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var messageLabel: UILabel!
  
  @IBOutlet weak var recordButton: UIButton!

  var session: ARSession {
    return sceneView.session
  }

  var contentTypeSelected: ContentType = .none

  var anchorNode: SCNNode?
  var mask: Mask?
  var maskType = MaskType.zombie
  var glasses: Glasses?
  var pig: Pig?

    
    
    
  // MARK: - View Management

  override func viewDidLoad() {
    super.viewDidLoad()
    setupScene()
    createFaceGeometry()
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

  // MARK: - Button Actions

  @IBAction func didTapReset(_ sender: Any) {
    print("didTapReset")
    contentTypeSelected = .none
    resetTracking()
  }

  @IBAction func didTapMask(_ sender: Any) {
    print("didTapMask")

    switch maskType {
    case .basic:
      maskType = .zombie
    case .painted:
      maskType = .basic
    case .zombie:
      maskType = .painted
    }

    mask?.swapMaterials(maskType: maskType)

    contentTypeSelected = .mask
    resetTracking()
  }

  @IBAction func didTapGlasses(_ sender: Any) {
    print("didTapGlasses")
    contentTypeSelected = .glasses
    resetTracking()
  }

  @IBAction func didTapPig(_ sender: Any) {
    print("didTapPig")
    contentTypeSelected = .pig
    resetTracking()
  }

  @IBAction func didTapRecord(_ sender: Any) {
    print("didTapRecord")
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
    let intensityStr = String(format: "%.2f", intensity)
    let sceneLighting = String(format: "%.2f",
                               sceneView.scene.lightingEnvironment.intensity)

    // 4
    print("Intensity: \(intensityStr) - \(sceneLighting)")
  }

  // Tag: ARNodeTracking
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    anchorNode = node
    setupFaceNodeContent()
  }

  // Tag: ARFaceGeometryUpdate
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let faceAnchor = anchor as? ARFaceAnchor else { return }
    updateMessage(text: "Tracking your face.")

    switch contentTypeSelected {
    case .none: break
    case .mask:
      mask?.update(withFaceAnchor: faceAnchor)
    case .glasses:
      glasses?.update(withFaceAnchor: faceAnchor)
    case .pig:
      pig?.update(withFaceAnchor: faceAnchor)
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
    sceneView.showsStatistics = true

    // Setup environment
    sceneView.automaticallyUpdatesLighting = true /* default setting */
    sceneView.autoenablesDefaultLighting = false /* default setting */
    sceneView.scene.lightingEnvironment.intensity = 1.0 /* default setting */
  }

  // Tag: ARFaceTrackingConfiguration
  func resetTracking() {
    // 1
    guard ARFaceTrackingConfiguration.isSupported else {
      updateMessage(text: "Face Tracking Not Supported.")
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
    updateMessage(text: "Creating face geometry.")

    let device = sceneView.device!

    let maskGeometry = ARSCNFaceGeometry(device: device)!
    mask = Mask(geometry: maskGeometry, maskType: maskType)

    let glassesGeometry = ARSCNFaceGeometry(device: device)!
    glasses = Glasses(geometry: glassesGeometry)

    let pigGeometry = ARSCNFaceGeometry(device: device)!
    pig = Pig(geometry: pigGeometry)
  }

  // Tag: Setup Face Content Nodes
  func setupFaceNodeContent() {
    guard let node = anchorNode else { return }

    node.childNodes.forEach { $0.removeFromParentNode() }

    switch contentTypeSelected {
    case .none: break
    case .mask:
      if let content = mask {
        node.addChildNode(content)
      }
    case .glasses:
      if let content = glasses {
        node.addChildNode(content)
      }
    case .pig:
      if let content = pig {
        node.addChildNode(content)
      }
    }
  }

  // Tag: Update UI
  func updateMessage(text: String) {
    DispatchQueue.main.async {
      self.messageLabel.text = text
    }
  }
}
