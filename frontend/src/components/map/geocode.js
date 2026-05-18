// Geocodificación inversa: lat/lng → dirección legible.
// Usa el Geocoder de Google ya cargado. Best-effort: si falla, null.
export function reverseGeocode(lat, lng) {
  return new Promise((resolve) => {
    if (!window.google?.maps) {
      resolve(null);
      return;
    }
    try {
      const geocoder = new window.google.maps.Geocoder();
      geocoder.geocode({ location: { lat, lng } }, (results, status) => {
        if (status === 'OK' && results?.[0]) {
          resolve(results[0].formatted_address);
        } else {
          resolve(null);
        }
      });
    } catch {
      resolve(null);
    }
  });
}
