app = angular.module 'weather-data-app', []

track_wetness_str = [
        "Unknown",
        "Dry",
        "Mostly Dry",
        "Very Lightly Wet",
        "Lightly Wet",
        "Moderately Wet",
        "Very Wet",
        "Extremely Wet",
    ]

app.config ($locationProvider) ->
    $locationProvider.html5Mode(true).hashPrefix('')

app.service 'config', ($location) ->
    vars = $location.search()

    console.log 'vars.showAirPressure: ', vars.showAirPressure
    console.log 'vars.showAirDensity: ', vars.showAirDensity
    console.log 'vars.showPrecipitation: ', vars.showPrecipitation
    console.log 'vars.showTrackWetness: ', vars.showTrackWetness
    console.log 'vars.bgOpacity: ', vars.bgOpacity

    showAirPressure: vars.showAirPressure == 'true'
    showAirDensity: vars.showAirDensity == 'true'
    showPrecipitation: vars.showPrecipitation != 'false'
    showTrackWetness: vars.showTrackWetness != 'false'
    bgOpacity: vars.bgOpacity || 0.7

app.service 'iRService', ($rootScope) ->
    ir = new IRacing ['TrackWetness', 'Precipitation', 'Skies', 'AirDensity', 'AirPressure'], [], 10

    ir.onConnect = ->        
        
        ir.CustomTrackWetnessStr = track_wetness_str[0]
        ir.data.CustomLastPrecipitation = 0
        ir.data.CustomPrecipitationState = 0
        ir.data.CustomPrecipitationStr = '0.0%'
        ir.data.CustomAirDensityStr = '0  kg/m³'
        ir.data.CustomAirPressureStr = '0  kPa'

        $rootScope.$apply()
        console.log 'connected'

    ir.onDisconnect = ->
        console.log 'disconnected'

    ir.onUpdate = (keys) ->
        $rootScope.$apply()

    return ir

app.controller 'WeatherCtrl', ($scope, iRService, config) ->
    $scope.ir = ir = iRService.data
    $scope.showAirPressure = config.showAirPressure
    $scope.showAirDensity = config.showAirDensity
    $scope.showPrecipitation = config.showPrecipitation
    $scope.showTrackWetness = config.showTrackWetness

    
    ir.CustomTrackWetnessStr = track_wetness_str[0]
    ir.CustomLastPrecipitation = 0
    ir.CustomPrecipitationState = 0
    ir.CustomPrecipitationStr = '0.0%'
    ir.CustomAirDensityStr = '0  kg/m³'
    ir.CustomAirPressureStr = '0  kPa'

    console.log '$scope.showAirPressure: ', $scope.showAirPressure
    console.log '$scope.showAirDensity: ', $scope.showAirDensity
    console.log '$scope.showPrecipitation: ', $scope.showPrecipitation
    console.log '$scope.showTrackWetness: ', $scope.showTrackWetness
    console.log 'config.bgOpacity: ', config.bgOpacity

    document.documentElement.style.setProperty("--theme-bg-color", "hsla(0, 0%, 6%, #{config.bgOpacity})")

    window.addEventListener "resize", onResize = () ->
        console.log "resize fired"
        ch = undefined
        cw = undefined
        sh = undefined
        sw = undefined
        v = 10
        vmax = 100
        vmin = 1
        wrapEl = document.querySelector(".app > .wrap")
        rootStyle = document.documentElement.style
        
        while !(Math.abs(vmin - vmax) < .1)
            rootStyle.setProperty("--app-font-size", "#{v}vmin")
            rootStyle.setProperty("--app-icon-font-size", "#{v}vmin")
            {clientWidth: cw, clientHeight: ch, scrollWidth: sw, scrollHeight: sh} = wrapEl
            if sw > cw || sh > ch
                vmax = v
            else
                if cw <= sw && ch <= sh 
                    vmin = v
            v = (vmin + vmax) / 2

    window.addEventListener "load", onLoad = () ->
        console.log "load fired"
        onResize()

    $scope.$watch 'ir.TrackWetness', onTrackWetness = (w) ->
        
        console.log 'TrackWetness: ', w
        if w != undefined 
            ir.CustomTrackWetnessStr = track_wetness_str[w]

    $scope.$watch 'ir.Precipitation', onPrecipitation = (p) ->
        console.log 'Precipitation: ', p
        if p != undefined 

            if p == 0
                ir.CustomPrecipitationState = 0
            else if p > ir.CustomLastPrecipitation
                ir.CustomPrecipitationState = 1
            else if p < ir.CustomLastPrecipitation
                ir.CustomPrecipitationState = 2
        
            ir.CustomPrecipitationStr = (p * 100).toFixed(1) + '%'
            ir.CustomLastPrecipitation = p
        
    $scope.$watch 'ir.AirDensity', onAirDensity = (d) ->
        
        # console.log 'AirDensity: ', d
        if d != undefined 
            ir.CustomAirDensityStr = d.toFixed(3) + ' kg/m³'

    $scope.$watch 'ir.AirPressure', onAirPressure = (p) ->
        
        # console.log 'AirPressure: ', p
        if p != undefined 
            ir.CustomAirPressureStr = (p / 1000).toFixed(3) + ' kPa'

angular.bootstrap document, [app.name]