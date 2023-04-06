import { defineLambertProjection } from './define-lambert-projection.js'
import { $fetchAvailableDestinationsFromID } from './available-destinations.coffee'

export class LambertYmap
    constructor: (options) ->
        @appState = options.appState
        @cities = options.cities
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?apikey=49de5080-fb39-46f1-924b-dee5ddbad2f1&lang=ru-RU'
            appState: null
            acceptableDistance: 1000
            worldFill: '#EAF3FB'
            genericFill: '#B6D7E3'
            genericStroke: '#FFFFFF'
            homeRegionFill: '#1EBDFF'
#            homeRegionFill: '#0093D0'
            options...
        }
        @bordersLoaded = new Promise (resolve) => @bordersLoadedResolve = resolve
    init: () ->
        $(@appState).on 'changed', (...params) => @appStateChanged(...params)

        @$ymap = $ @options.el
        ymaps_api_callback = "ymaps_loaded_#{ Math.round(Math.random() * 1000000) }"
        window[ymaps_api_callback] = () => @ymapsInit()
        $.ajax
            url: @options.ymaps_api + "&onload=#{ ymaps_api_callback }"
            dataType: 'script'
            cache: true
        .done () =>
            console.log "*** ymaps_api loaded"
        # wait for wheel zoom modifier key (Alt)
#        $(document).on 'keyup keydown', (e) =>
#            if [18].indexOf(e.which) >= 0
#                @zoom_modifier_down = e.type == 'keydown'
        @

    ymapsInit: () ->
        console.log '*** ymapsInit'
        LAMBERT_PROJECTION = await defineLambertProjection()
        window.ymap = @ymap = new ymaps.Map @$ymap.get(0),
            center:   [65, 90],
            zoom:     2,
            type:     null,
            controls: ['zoomControl']
        ,
            minZoom: 1,
            projection: new LAMBERT_PROJECTION()
#        @ymap.controls.get('zoomControl').options.set size: 'small'

        pane = new ymaps.pane.StaticPane @ymap,
            css: width: '100%', height: '100%', backgroundColor: @options.worldFill
            zIndex: 100
        @ymap.panes.append 'coralPageBackground', pane

        ymaps.borders.load 'RU', lang: 'ru', quality: 1
        .then (result) =>
            console.log result
            @regions = new ymaps.GeoObjectCollection null,
                fillColor:   @options.genericFill,
                strokeColor: @options.genericStroke,
                hasHint:     false,
                cursor:      'default'
            for feature in result.features
                @regions.add new ymaps.GeoObject feature
            @ymap.geoObjects.add @regions
            @bordersLoadedResolve yes
#            @ymap.setBounds @ymap.geoObjects.getBounds(), duration: 1000


#        @$scrollZoomHint = $('.scrollzoom-hint')
#        @scrollZoomTimeout = 0
#        @scrollZoomUsed = false
#        @ymap.events.add 'wheel', (e) =>
#            if @zoom_modifier_down
#                @$scrollZoomHint.removeClass 'shown'
#                @scrollZoomUsed = true
#            else
#                e.preventDefault()
#                unless @scrollZoomUsed
#                    @$scrollZoomHint.addClass 'shown'
#                    clearTimeout @scrollZoomTimeout
#                    @scrollZoomTimeout = setTimeout () =>
#                        @$scrollZoomHint.removeClass 'shown'
#                    , 1000

    appStateChanged: (e, ...changes_list) ->
        if changes_list.includes 'homeCity'
            await @bordersLoaded
            await @setHomeCity @appState.get 'homeCity'
            @setPreferredDestination @appState.get 'preferredDestination'
        if changes_list.includes 'preferredDestination'
            @setPreferredDestination @appState.get 'preferredDestination'

    findRegionByCity: (city) ->
        @regions.toArray().find (region) -> region.geometry.contains city.latlng

    getHomeCity: () -> _.find @cities, 'isHomecity'

    setHomeCity: (city) ->
        homecity = @getHomeCity()
        if homecity and city != homecity
            homecity.placemark.remove()
            homecity.region.options.set 'fillColor', @options.genericFill
            delete homecity.isHomecity
        if city != homecity
            return new Promise (resolve) =>
                city.placemark = new ymaps.Placemark city.latlng unless city.placemark
                @ymap.geoObjects.add city.placemark
                city.region ||= @findRegionByCity city
                city.region.options.set 'fillColor', @options.homeRegionFill
                city.isHomecity = yes
                @cities.sort (a, b) ->
                    a.distanceFromHome = da = a.latlng.distanceFrom(city.latlng)
                    b.distanceFromHome = db = b.latlng.distanceFrom(city.latlng)
                    if da < db then -1 else if da > db then 1 else 0
                if city.availableDestinations
                    resolve yes
                else
                    $fetchAvailableDestinationsFromID city.eeID
                        .then (destinations_response) ->
                            city.availableDestinations = destinations_response
                            resolve yes
        yes

    setPreferredDestination: (destination_name_or_id) ->
        home_city = @getHomeCity()
        console.log "+++ setPreferredDestination: %o", destination_name_or_id
        preferred_destination_available = home_city.availableDestinations.find (d) -> d.Name == destination_name_or_id or d.Id == destination_name_or_id
        cities2check = @cities.filter (city, idx) => idx != 0 and city.distanceFromHome < @options.acceptableDistance or city.eeID == 2671
        cities_with_preferred_destination = cities2check.filter (city) =>
            ad = city.availableDestinations or await new Promise (resolve) ->
                $fetchAvailableDestinationsFromID(city.eeID).then (r) ->
                    city.availableDestinations = r
                    resolve r
            console.log ad
            ad.find (d) -> d.Name == destination_name_or_id or d.Id == destination_name_or_id
        console.log "+++ cities_with_preferred_destination: %o", cities_with_preferred_destination

