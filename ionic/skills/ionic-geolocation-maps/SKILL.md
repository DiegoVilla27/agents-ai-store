---
name: ionic-geolocation-maps
description: The ultimate architectural standard for Geolocation, Native Maps Integration, Permission Handling, and Location Tracking in Ionic/Capacitor.
author: Diego Villanueva
trigger: When implementing GPS location, displaying maps, tracking user position, or managing location permissions.
---

# Enterprise Ionic Geolocation & Maps Architecture

Location-aware features are essential for ride-sharing, delivery, fitness, and social apps. Capacitor provides native GPS access with proper permission handling across iOS and Android.

## 1. Geolocation Service

```typescript
// core/plugins/geolocation.service.ts
import { Injectable, signal } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { Geolocation, Position, PermissionStatus } from '@capacitor/geolocation';

export interface GeoCoordinates {
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: number;
}

@Injectable({ providedIn: 'root' })
export class GeolocationService {
  readonly currentPosition = signal<GeoCoordinates | null>(null);
  readonly permissionStatus = signal<string>('prompt');
  private watchId: string | null = null;

  async getCurrentPosition(): Promise<GeoCoordinates> {
    await this.ensurePermission();

    const position: Position = await Geolocation.getCurrentPosition({
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 5000, // Accept cached position up to 5s old
    });

    const coords: GeoCoordinates = {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
      accuracy: position.coords.accuracy,
      timestamp: position.timestamp,
    };

    this.currentPosition.set(coords);
    return coords;
  }

  async startWatching(callback: (coords: GeoCoordinates) => void): Promise<void> {
    await this.ensurePermission();

    this.watchId = await Geolocation.watchPosition(
      { enableHighAccuracy: true },
      (position, err) => {
        if (err) {
          console.error('Watch position error:', err);
          return;
        }
        if (position) {
          const coords: GeoCoordinates = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            timestamp: position.timestamp,
          };
          this.currentPosition.set(coords);
          callback(coords);
        }
      }
    );
  }

  async stopWatching(): Promise<void> {
    if (this.watchId) {
      await Geolocation.clearWatch({ id: this.watchId });
      this.watchId = null;
    }
  }

  async checkPermission(): Promise<PermissionStatus> {
    const status = await Geolocation.checkPermissions();
    this.permissionStatus.set(status.location);
    return status;
  }

  private async ensurePermission(): Promise<void> {
    const status = await this.checkPermission();

    if (status.location === 'denied') {
      throw new Error('Location permission denied. Please enable in Settings.');
    }

    if (status.location !== 'granted') {
      const result = await Geolocation.requestPermissions();
      if (result.location !== 'granted') {
        throw new Error('Location permission not granted');
      }
    }
  }
}
```

## 2. Google Maps Integration

For rich map displays, use `@capacitor/google-maps` which renders a native map view:

```bash
npm install @capacitor/google-maps
```

```typescript
// features/maps/pages/map.page.ts
import { Component, ElementRef, ViewChild, AfterViewInit, signal, inject } from '@angular/core';
import { GoogleMap } from '@capacitor/google-maps';
import { IonContent, IonHeader, IonToolbar, IonTitle, IonFab, IonFabButton, IonIcon } from '@ionic/angular/standalone';
import { environment } from '@env/environment';

@Component({
  selector: 'app-map',
  standalone: true,
  imports: [IonContent, IonHeader, IonToolbar, IonTitle, IonFab, IonFabButton, IonIcon],
  template: `
    <ion-header>
      <ion-toolbar>
        <ion-title>Map</ion-title>
      </ion-toolbar>
    </ion-header>
    <ion-content>
      <capacitor-google-map #map style="display: block; width: 100%; height: 100%;"></capacitor-google-map>

      <ion-fab vertical="bottom" horizontal="end" slot="fixed">
        <ion-fab-button (click)="centerOnUser()">
          <ion-icon name="locate" />
        </ion-fab-button>
      </ion-fab>
    </ion-content>
  `,
})
export class MapPage implements AfterViewInit {
  @ViewChild('map') mapRef!: ElementRef<HTMLElement>;
  private map!: GoogleMap;
  private readonly geoService = inject(GeolocationService);

  async ngAfterViewInit(): Promise<void> {
    const position = await this.geoService.getCurrentPosition();

    this.map = await GoogleMap.create({
      id: 'main-map',
      element: this.mapRef.nativeElement,
      apiKey: environment.googleMapsKey,
      config: {
        center: { lat: position.latitude, lng: position.longitude },
        zoom: 15,
      },
    });

    // Add user marker
    await this.map.addMarker({
      coordinate: { lat: position.latitude, lng: position.longitude },
      title: 'You are here',
    });

    // Listen to map events
    await this.map.setOnMarkerClickListener((marker) => {
      console.log('Marker clicked:', marker);
    });
  }

  async centerOnUser(): Promise<void> {
    const position = await this.geoService.getCurrentPosition();
    await this.map.setCamera({
      coordinate: { lat: position.latitude, lng: position.longitude },
      zoom: 16,
      animate: true,
    });
  }

  ionViewDidLeave(): void {
    this.map?.destroy();
  }
}
```

## 3. Distance Calculation

```typescript
// shared/utils/geo.utils.ts
export function calculateDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}
```

---

**Execution Protocol**
1. **Always request location permission with context**: Show users a dialog explaining WHY you need their location before calling `requestPermissions()`.
2. **Always stop watching when leaving the page**: Use `ionViewDidLeave` to call `stopWatching()`.
3. **Always destroy native maps on page leave**: Prevent memory leaks by calling `map.destroy()`.
4. **Use `enableHighAccuracy: true` for GPS**: Without it, the device may use Wi-Fi triangulation (less accurate).
5. **Always set a `timeout`**: Prevent the app from hanging if GPS is unavailable (e.g., inside a building).
