pragma Singleton

import QtQuick
import Quickshell
import "../theme"

QtObject {
    id: root

    // --- State Properties ---
    property string city: "Bengaluru"
    property string loc: "12.9715,77.5945"
    property bool loaded: false
    property bool loading: false
    property bool useFahrenheit: true

    // Current conditions
    property real currentTempC: 28.0
    property real currentFeelsLikeC: 29.5
    property int currentHumidity: 48
    property real currentWindSpeed: 14.3
    property string weatherCode: "51"
    property string sunrise: "6:15 AM"
    property string sunset: "5:51 PM"

    // Formatted readouts
    readonly property string icon: getWeatherIcon(weatherCode)
    readonly property string condition: getWeatherCondition(weatherCode)
    readonly property string temp: formatTemp(currentTempC)
    readonly property string feelsLike: formatTemp(currentFeelsLikeC)
    readonly property int humidity: currentHumidity
    readonly property string windSpeed: currentWindSpeed.toFixed(1) + " km/h"

    // 7-day forecast model
    property var forecast: [
        { day: "Today", date: "Nov 8", icon: "rainy", minTemp: 68, maxTemp: 84, minTempC: 19.9, maxTempC: 28.7 },
        { day: "Mon", date: "Nov 9", icon: "rainy", minTemp: 67, maxTemp: 82, minTempC: 19.4, maxTempC: 28.0 },
        { day: "Tue", date: "Nov 10", icon: "cloud", minTemp: 65, maxTemp: 83, minTempC: 18.4, maxTempC: 28.5 },
        { day: "Wed", date: "Nov 11", icon: "cloud", minTemp: 65, maxTemp: 84, minTempC: 18.5, maxTempC: 28.9 },
        { day: "Thu", date: "Nov 12", icon: "cloud", minTemp: 64, maxTemp: 85, minTempC: 17.7, maxTempC: 29.2 },
        { day: "Fri", date: "Nov 13", icon: "partly_cloudy_day", minTemp: 62, maxTemp: 85, minTempC: 16.6, maxTempC: 29.4 },
        { day: "Sat", date: "Nov 14", icon: "cloud", minTemp: 64, maxTemp: 86, minTempC: 17.5, maxTempC: 29.9 }
    ]

    function toggleUnit(): void {
        useFahrenheit = !useFahrenheit;
        updateForecastFormatted();
    }

    function formatTemp(celsius: real, compact = false): string {
        if (celsius === undefined || isNaN(celsius)) return "--";
        const val = useFahrenheit ? Math.round(celsius * 9 / 5 + 32) : Math.round(celsius);
        return compact ? val + "°" : (val + (useFahrenheit ? "°F" : "°C"));
    }

    function updateForecastFormatted(): void {
        if (!forecast || forecast.length === 0) return;
        const list = [];
        for (let i = 0; i < forecast.length; i++) {
            const item = forecast[i];
            const min = formatTemp(item.minTempC, true);
            const max = formatTemp(item.maxTempC, true);
            list.push({
                day: item.day,
                date: item.date,
                icon: item.icon,
                minTemp: item.minTemp,
                maxTemp: item.maxTemp,
                minTempC: item.minTempC,
                maxTempC: item.maxTempC,
                tempRange: min + " / " + max
            });
        }
        forecast = list;
    }

    // Material Symbols matching Caelestia shell
    function getWeatherIcon(code: string): string {
        const icons = {
            "0": "clear_day",
            "1": "clear_day",
            "2": "partly_cloudy_day",
            "3": "cloud",
            "45": "foggy",
            "48": "foggy",
            "51": "rainy",
            "53": "rainy",
            "55": "rainy",
            "56": "rainy",
            "57": "rainy",
            "61": "rainy",
            "63": "rainy",
            "65": "rainy",
            "66": "rainy",
            "67": "rainy",
            "71": "cloudy_snowing",
            "73": "cloudy_snowing",
            "75": "snowing_heavy",
            "77": "cloudy_snowing",
            "80": "rainy",
            "81": "rainy",
            "82": "rainy",
            "85": "cloudy_snowing",
            "86": "snowing_heavy",
            "95": "thunderstorm",
            "96": "thunderstorm",
            "99": "thunderstorm"
        };
        return icons[String(code)] || "cloud";
    }

    function getWeatherCondition(code: string): string {
        const conditions = {
            "0": "Clear",
            "1": "Mainly clear",
            "2": "Partly cloudy",
            "3": "Overcast",
            "45": "Fog",
            "48": "Depositing rime fog",
            "51": "Drizzle",
            "53": "Moderate drizzle",
            "55": "Dense drizzle",
            "56": "Light freezing drizzle",
            "57": "Dense freezing drizzle",
            "61": "Slight rain",
            "63": "Moderate rain",
            "65": "Heavy rain",
            "66": "Light freezing rain",
            "67": "Heavy freezing rain",
            "71": "Slight snow fall",
            "73": "Moderate snow fall",
            "75": "Heavy snow fall",
            "77": "Snow grains",
            "80": "Slight rain showers",
            "81": "Moderate rain showers",
            "82": "Violent rain showers",
            "85": "Slight snow showers",
            "86": "Heavy snow showers",
            "95": "Thunderstorm",
            "96": "Thunderstorm with slight hail",
            "99": "Thunderstorm with heavy hail"
        };
        return conditions[String(code)] || "Clear";
    }

    function formatTime12(isoStr: string): string {
        if (!isoStr) return "--:--";
        try {
            const parts = isoStr.split("T");
            if (parts.length > 1) {
                const timeParts = parts[1].split(":");
                let h = parseInt(timeParts[0], 10);
                const m = timeParts[1];
                const ampm = h >= 12 ? "PM" : "AM";
                h = h % 12;
                if (h === 0) h = 12;
                return h + ":" + m + " " + ampm;
            }
        } catch (e) {}
        return isoStr;
    }

    function reload(): void {
        if (loading) return;
        loading = true;

        // Step 1: Detect IP coordinates and city
        const xhrIp = new XMLHttpRequest();
        xhrIp.open("GET", "http://ip-api.com/json?fields=status,city,lat,lon");
        xhrIp.onreadystatechange = function() {
            if (xhrIp.readyState === XMLHttpRequest.DONE) {
                if (xhrIp.status === 200) {
                    try {
                        const res = JSON.parse(xhrIp.responseText);
                        if (res.status === "success") {
                            root.city = res.city || "Bengaluru";
                            root.loc = res.lat + "," + res.lon;
                            fetchOpenMeteo(res.lat, res.lon);
                            return;
                        }
                    } catch (e) {}
                }
                // Fallback coordinates for Bengaluru
                fetchOpenMeteo(12.9715, 77.5945);
            }
        };
        xhrIp.send();
    }

    function fetchOpenMeteo(lat: real, lon: real): void {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat +
            "&longitude=" + lon +
            "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m" +
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset" +
            "&timezone=auto&forecast_days=7";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false;
                if (xhr.status === 200) {
                    try {
                        const json = JSON.parse(xhr.responseText);
                        if (json.current) {
                            root.currentTempC = json.current.temperature_2m;
                            root.currentFeelsLikeC = json.current.apparent_temperature;
                            root.currentHumidity = Math.round(json.current.relative_humidity_2m);
                            root.currentWindSpeed = json.current.wind_speed_10m;
                            root.weatherCode = String(json.current.weather_code);
                        }
                        if (json.daily) {
                            if (json.daily.sunrise && json.daily.sunrise.length > 0) {
                                root.sunrise = formatTime12(json.daily.sunrise[0]);
                            }
                            if (json.daily.sunset && json.daily.sunset.length > 0) {
                                root.sunset = formatTime12(json.daily.sunset[0]);
                            }

                            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                            const forecastList = [];

                            for (let i = 0; i < json.daily.time.length; i++) {
                                const d = new Date(json.daily.time[i] + "T00:00:00");
                                const dayName = i === 0 ? "Today" : days[d.getDay()];
                                const dateStr = months[d.getMonth()] + " " + d.getDate();
                                const code = String(json.daily.weather_code[i]);
                                const minC = json.daily.temperature_2m_min[i];
                                const maxC = json.daily.temperature_2m_max[i];

                                forecastList.push({
                                    day: dayName,
                                    date: dateStr,
                                    icon: getWeatherIcon(code),
                                    minTemp: Math.round(minC * 9 / 5 + 32),
                                    maxTemp: Math.round(maxC * 9 / 5 + 32),
                                    minTempC: minC,
                                    maxTempC: maxC,
                                    tempRange: ""
                                });
                            }
                            root.forecast = forecastList;
                            updateForecastFormatted();
                        }
                        root.loaded = true;
                    } catch (err) {
                        console.warn("Error parsing weather JSON:", err);
                    }
                }
            }
        };
        xhr.send();
    }

    // Auto-fetch on boot
    Component.onCompleted: {
        reload();
    }

    // Refresh every 30 minutes
    property var refreshTimer: Timer {
        interval: 1800000 // 30 minutes
        repeat: true
        running: true
        onTriggered: root.reload()
    }
}
