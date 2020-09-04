//
//  ViewController.swift
//  BeelineChellenge
//
//  Created by Hsieh on 2020/9/4.
//  Copyright © 2020 Hsieh. All rights reserved.
//

import UIKit
import Combine
import MapKit

class ViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Property
    private var startAnnotation: MKPointAnnotation? = nil {
        didSet {
            guard isViewLoaded else { return }
            if let oldAnnotation = oldValue {
                mapView.removeAnnotation(oldAnnotation)
            }
            if let annotation = startAnnotation {
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    private var endAnnotation: MKPointAnnotation? = nil {
        didSet {
            guard isViewLoaded else { return }
            if let oldAnnotation = oldValue {
                mapView.removeAnnotation(oldAnnotation)
            }
            if let annotation = endAnnotation {
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    private var viewModel: ViewModel!
    private var disposeBag = Set<AnyCancellable>()
    
    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        viewModel = ViewModel()
        
        viewModel.actionButtonEnabled
            .assign(to: \.isEnabled, on: actionButton)
            .store(in: &disposeBag)
        
        viewModel.actionButtonTitle
            .sink { [actionButton] in actionButton?.title = $0 }
            .store(in: &disposeBag)
        
        // start annotation
        viewModel.startLocation.map { coordinate -> MKPointAnnotation? in
            guard let coordinate = coordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.title = "START"
            annotation.coordinate = coordinate
            return annotation
        }
        .assign(to: \.startAnnotation, on: self)
        .store(in: &disposeBag)
        
        // end annotation
        viewModel.endLocation.map { coordinate -> MKPointAnnotation? in
            guard let coordinate = coordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.title = "END"
            annotation.coordinate = coordinate
            return annotation
        }
        .assign(to: \.endAnnotation, on: self)
        .store(in: &disposeBag)
        
        
        // draw line while tracking
        viewModel.locationList
            .combineLatest(viewModel.isTracking)
            .filter { $0.1 }
            .map { $0.0 }
            .sink { [weak self] in self?.drawLine(to: $0) }
            .store(in: &disposeBag)
        
        // update current location
        viewModel.locationList
            .compactMap(\.last)
            .sink { [mapView] in mapView?.centerToLocation($0) }
            .store(in: &disposeBag)
        
        viewModel.viewDidLoad()
    }
    
    // MARK: IBAction
    @IBAction func startOrStop(_ sender: Any) {
        viewModel.actionButtonDidTap()
    }
    
    // MARK: Private Method
    private func setupMapView() {
        mapView.showsUserLocation = true
    }
    
    private func drawLine(to locations: [CLLocation]) {
        print("drawLine", locations)
    }
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 100
    ) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        setRegion(coordinateRegion, animated: true)
    }
}
