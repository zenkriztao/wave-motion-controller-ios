import UIKit


let MaxDataEntries = 500
let DefaultEEGHistory = Array<EEGSnapshot>(count: MaxDataEntries, repeatedValue: EEGSnapshot.allZeros)


class MainViewController: UIViewController {
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    @IBOutlet weak var deltaWaveView: WaveView!
    @IBOutlet weak var thetaWaveView: WaveView!
    @IBOutlet weak var lowAlphaWaveView: WaveView!
    @IBOutlet weak var highAlphaWaveView: WaveView!
    @IBOutlet weak var lowBetaWaveView: WaveView!
    @IBOutlet weak var highBetaWaveView: WaveView!
    @IBOutlet weak var lowGammaWaveView: WaveView!
    @IBOutlet weak var highGammaWaveView: WaveView!
    @IBOutlet var waveformViews: [WaveView]!
    
    var eegDataHistory: [EEGSnapshot] = DefaultEEGHistory
    let accessoryManager = TGAccessoryManager.sharedTGAccessoryManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPreviousEEGData()
        
        updateWaveformViews()
        
        accessoryManager.setupManagerWithInterval(0.05)
        accessoryManager.delegate = self
        accessoryManager.rawEnabled = false
        
        initiateStreamIfPossible()
    }
    
    deinit {
        accessoryManager.teardownManager()
    }
    
    func initiateStreamIfPossible() {
        if accessoryManager.accessory != nil {
            accessoryManager.startStream()
        }
    }
    
    func updateWaveformViews() {
        connectionStatusLabel.text = accessoryManager.connected ? accessoryManager.accessory.name : "No device connected"
        
        func extractBandData(extractValue: EEGSnapshot -> Int) -> [Int] {
            return eegDataHistory.map(extractValue)
        }
        
        deltaWaveView.points = extractBandData { $0.delta }
        thetaWaveView.points = extractBandData { $0.theta }
        lowAlphaWaveView.points = extractBandData { $0.lowAlpha }
        highAlphaWaveView.points = extractBandData { $0.highAlpha }
        lowBetaWaveView.points = extractBandData { $0.lowBeta }
        highBetaWaveView.points = extractBandData { $0.highBeta }
        lowGammaWaveView.points = extractBandData { $0.lowGamma }
        highGammaWaveView.points = extractBandData { $0.highGamma }
    }
}


// MARK: Accessory delegate
extension MainViewController: TGAccessoryDelegate {
    func dataReceived(data: [NSObject:AnyObject]!) {
        eegDataHistory.append(EEGSnapshot(dictionary: data as NSDictionary))
        
        // Trim the data history to prevent overflow
        eegDataHistory.removeRange(0 ..< max(0, eegDataHistory.count - MaxDataEntries))
        
        saveEEGDataHistory()
        updateWaveformViews()
    }
    
    func accessoryDidConnect(accessory: EAAccessory!) {
        initiateStreamIfPossible()
        updateWaveformViews()
    }
    
    func accessoryDidDisconnect() {
        updateWaveformViews()
    }
}


// MARK: EEG Data Management
extension MainViewController {
    func loadPreviousEEGData() {
        if let savedData = NSUserDefaults.standardUserDefaults().arrayForKey("eegDataHistory") {
            eegDataHistory = savedData.map { EEGSnapshot(dictionary: $0 as! NSDictionary) }
        }
    }
    
    func saveEEGDataHistory() {
        let savedData = eegDataHistory.map { NSDictionary(eegSnapshot: $0) }
        NSUserDefaults.standardUserDefaults().setObject(savedData, forKey: "eegDataHistory")
    }
}


// MARK: Actions
extension MainViewController {
    @IBAction func resetData(sender: UIButton) {
        eegDataHistory = DefaultEEGHistory
        updateWaveformViews()
    }
}
