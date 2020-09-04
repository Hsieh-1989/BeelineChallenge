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
    private var viewModel: ViewModel!
    private var disposeBag = Set<AnyCancellable>()
    
    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        viewModel = ViewModel()
        viewModel.actionButtonTitle.sink { [actionButton] title in
            actionButton?.title = title
        }.store(in: &disposeBag)
        
        viewModel.locationList.compactMap(\.last).sink { [mapView] location in
            mapView?.centerToLocation(location)
        }.store(in: &disposeBag)
        
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
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 1000
    ) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        setRegion(coordinateRegion, animated: true)
    }
}
