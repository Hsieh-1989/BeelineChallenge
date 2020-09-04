//
//  LocationClient.swift
//  BeelineChellenge
//
//  Created by Hsieh on 2020/9/4.
//  Copyright © 2020 Hsieh. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

// adjust from: https://github.com/pointfreeco/episode-code-samples/tree/main/0114-designing-dependencies-pt5/DesigningDependencies/DesigningDependencies/LocationClient

struct LocationClient {
    
    enum Event {
        case didChangeAuthorization(CLAuthorizationStatus)
        case didUpdateLocations([CLLocation])
    }
    
    // MARK: Input
    let authorizationStatus: () -> CLAuthorizationStatus
    let requestAuthorization: () -> Void
    let startUpdatingLocation: () -> Void
    
    // MARK: Output
    let events: AnyPublisher<Event, Never>
}

extension LocationClient {
    
    private final class Delegate: NSObject, CLLocationManagerDelegate {
        
        let subject: PassthroughSubject<Event, Never>
        
        init(subject: PassthroughSubject<Event, Never>) {
            self.subject = subject
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            self.subject.send(.didChangeAuthorization(status))
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            self.subject.send(.didUpdateLocations(locations))
        }
    }
    
    static let live: Self = {
        let locationManager = CLLocationManager()
        let subject = PassthroughSubject<Event, Never>()
        
        var delegate: Delegate? = Delegate(subject: subject)
        locationManager.delegate = delegate
        
        return LocationClient(
            authorizationStatus: CLLocationManager.authorizationStatus,
            requestAuthorization: locationManager.requestAlwaysAuthorization,
            startUpdatingLocation: locationManager.startUpdatingLocation,
            events: subject
                .handleEvents(receiveCancel: { delegate = nil })
                .eraseToAnyPublisher()
        )
    }()
}
