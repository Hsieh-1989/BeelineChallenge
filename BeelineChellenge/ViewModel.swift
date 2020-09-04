//
//  ViewModel.swift
//  BeelineChellenge
//
//  Created by Hsieh on 2020/9/4.
//  Copyright © 2020 Hsieh. All rights reserved.
//

import Combine
import CoreLocation

struct TravelData {
    
    let start: Date
    let end: Date
    let distance: CLLocationDistance
    
    // km/hr
    var averageSpeed: Double {
        let totalTime = end.timeIntervalSince(start) / (60*60)
        return (distance / 1000) / totalTime
    }
}

final class ViewModel {
    
    enum State {
        case idle
        case tracking
        case finish
    }
    
    // MARK: Output
    var actionButtonEnabled: AnyPublisher<Bool, Never> {
        currentLocationsSubject
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    var actionButtonTitle: AnyPublisher<String, Never> {
        currentStateSubject
            .map(\.buttonTitle)
            .eraseToAnyPublisher()
    }
    
    var isTracking: AnyPublisher<Bool, Never> {
        currentStateSubject
            .map { $0 == .tracking }
            .eraseToAnyPublisher()
    }
    
    var startLocation: AnyPublisher<CLLocationCoordinate2D?, Never> {
        startLocationSubject.eraseToAnyPublisher()
    }
    
    var endLocation: AnyPublisher<CLLocationCoordinate2D?, Never> {
        endLocationSubject.eraseToAnyPublisher()
    }
    
    var locationList: AnyPublisher<[CLLocation], Never> {
        trackingLocationsSubject.eraseToAnyPublisher()
    }
    
    var travelData: AnyPublisher<TravelData, Never> {
        travelDataSubject.eraseToAnyPublisher()
    }
    
    // MARK: Private Property
    private var startTime: Date?
    private let currentStateSubject = CurrentValueSubject<State, Never>(.idle)
    private let currentLocationsSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let trackingLocationsSubject = CurrentValueSubject<[CLLocation], Never>([])
    
    private let startLocationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let endLocationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let travelDataSubject = PassthroughSubject<TravelData, Never>()
    
    private let locationClient: LocationClient
    private var disposeBag = Set<AnyCancellable>()
    
    // MARK: Initializer
    init(locationClient: LocationClient = .live) {
        self.locationClient = locationClient
    }
    
    // MARK: Input
    func viewDidLoad() {
        self.locationClient.events.sink { [weak self] event in
            switch event {
            case let .didChangeAuthorization(authorization):
                self?.didChangeAuthorization(authorization)
            case let .didUpdateLocations(locations):
                self?.didUpdateLocations(locations)
            }
        }.store(in: &disposeBag)
        requestAuthorizedIfNeeded()
    }
    
    func actionButtonDidTap() {
        // FIXME: Clean up the logic
        switch currentStateSubject.value {
        case .idle:
            currentStateSubject.send(.tracking)
            startTime = Date()
            
            if let location = currentLocationsSubject.value {
                startLocationSubject.send(location.coordinate)
            }
        case .tracking:
            if let location = currentLocationsSubject.value {
                endLocationSubject.send(location.coordinate)
            }
            currentStateSubject.send(.finish)
            buildTravelData()
            
        case .finish:
            trackingLocationsSubject.send([])
            startLocationSubject.send(nil)
            endLocationSubject.send(nil)
            currentStateSubject.send(.idle)
        }
    }
    
    // MARK: Private Helper
    private func requestAuthorizedIfNeeded() {
        guard locationClient.authorizationStatus() == .notDetermined else {
            return
        }
        locationClient.requestAuthorization()
    }
    
    private func didChangeAuthorization(_ authorization: CLAuthorizationStatus) {
        switch authorization {
        case .notDetermined:
            // seems a impossible case
            locationClient.requestAuthorization()
            
        case .restricted, .denied:
            // TODO: show alert
            break
            
        case .authorizedAlways, .authorizedWhenInUse:
            locationClient.startUpdatingLocation()
            
        @unknown default:
            break
        }
    }
    
    private func didUpdateLocations(_ locations: [CLLocation]) {
        guard let last = locations.last else { return }
        currentLocationsSubject.send(last)
        trackingLocationsSubject.send(trackingLocationsSubject.value + [last])
    }
    
    private func buildTravelData() {
        guard let start = startTime else { return }
        let distance: CLLocationDistance = zip(
            trackingLocationsSubject.value,
            trackingLocationsSubject.value.dropFirst()
        ).reduce(0) {
            $0 + $1.1.distance(from: $1.0)
        }
        let data = TravelData(start: start, end: .init(), distance: distance)
        travelDataSubject.send(data)
    }
}

// MARK: Constant
private extension ViewModel.State {
    var buttonTitle: String {
        switch self {
        case .idle: return .start
        case .tracking: return .stop
        case .finish: return .reset
        }
    }
}

private extension String {
    static let start = "START"
    static let stop = "STOP"
    static let reset = "RESET"
}
