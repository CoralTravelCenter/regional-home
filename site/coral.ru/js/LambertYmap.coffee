import { defineLambertProjection } from './define-lambert-projection.js'
import { $fetchAvailableDestinationsFromID } from './available-destinations.coffee'

import placemark_home from 'data-url:/site/coral.ru/inline-assets/placemark-home.svg'
import placemark_available from 'data-url:/site/coral.ru/inline-assets/placemark-available.svg'

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
            availableDestinationFill: '#F0AB0099'
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
        @projection = new LAMBERT_PROJECTION()
        @PlacemarkLayout = ymaps.templateLayoutFactory.createClass "<div class='city-placemark-label'>$[properties.iconContent]<span class='distance-from-home'>$[properties.distance2show]</span></div>"
        window.ymap = @ymap = new ymaps.Map @$ymap.get(0),
            center:   [65, 90]
            zoom:     2
            type:     null
#            margin: [70, 30, 10, 70]
            controls: ['zoomControl']
        ,
            minZoom: 2
            maxZoom: 6
            projection: @projection
#        @ymap.controls.get('zoomControl').options.set size: 'small'

        @backdropPane = new ymaps.pane.StaticPane @ymap,
            css: width: '100%', height: '100%', backgroundColor: @options.worldFill
            zIndex: 100
        @ymap.panes.append 'backdropPane', @backdropPane
        @routesPane = new ymaps.pane.MovablePane @ymap,
            css: width: '100%', height: '100%'
            zIndex: 300
        @ymap.panes.append 'routesPane', @routesPane

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
            # @ymap.setBounds @ymap.geoObjects.getBounds(), duration: 1000


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

    getAvailableCities: () -> _.filter @cities, 'isPreferredDestinationAvailable'

    setHomeCity: (city) ->
        homecity = @getHomeCity()
        if homecity and city != homecity
            @setStateForCity city, 'generic'
        if city != homecity
            return new Promise (resolve) =>
                @setStateForCity city, 'homecity'
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

    makeCityPlacemark: (city, imageHref) ->
        new ymaps.Placemark city.latlng,
            city: city
            iconContent: (city.correctName ? city.name)
        ,
            iconLayout: 'default#imageWithContent'
#            iconImageHref: imageHref
            iconImageSize: [33, 43]
            iconImageOffset: [-16, -43]
            iconContentOffset: [0, 2]
            iconContentLayout: @PlacemarkLayout

    setStateForCity: (city, state) ->
        city.region ||= @findRegionByCity city
        switch state
            when 'homecity'
                city.placemark ||= @makeCityPlacemark city
                city.placemark.options.set 'iconImageHref', placemark_home
                city.placemark.properties.set 'distance2show', undefined
                @ymap.geoObjects.add city.placemark
                regionFill = @options.homeRegionFill
                zIndex = 100
                city.isHomecity = yes
            when 'available'
                city.placemark ||= @makeCityPlacemark city
                city.placemark.options.set 'iconImageHref', placemark_available
                city.placemark.properties.set 'distance2show', " (#{ Math.round(city.distanceFromHome) } км)"
                @ymap.geoObjects.add city.placemark
                unless city.region.options.get('fillColor') == @options.homeRegionFill
                    regionFill = @options.availableDestinationFill
                city.isPreferredDestinationAvailable = yes
            when 'generic'
                delete city.isHomecity
                delete city.isPreferredDestinationAvailable
                regionFill = @options.genericFill
                city.placemark.properties.set 'distance2show', undefined
                city.placemark?.getParent().remove(city.placemark)
            else
                delete city.isHomecity
                delete city.isPreferredDestinationAvailable
                unless city.region.options.get('fillColor') == @options.homeRegionFill
                    regionFill = @options.genericFill
                city.placemark?.getParent().remove(city.placemark)
        city.region.options.set 'fillColor', regionFill if regionFill
        city.region.options.set 'zIndex', zIndex

    drawRoutes: () ->
        routes_el = @routesPane.getElement()
#        routes_viewport = @routesPane.getViewport()
        unless @draw
            @draw = SVG().attr(id: 'routes-svg')
            @draw.addTo routes_el
            @ymap.events.add 'boundschange', (e) => @drawRoutes()
            @ymap.events.add 'actionend', (e) => @drawRoutes()
            # @routesPane.events.add 'clientpixelschange', (e) => @drawRoutes()
        [[tl_x, tl_y], [br_x, br_y]] = @ymap.getGlobalPixelBounds()
        @draw.viewbox tl_x, tl_y, br_x - tl_x, br_y - tl_y
        from_p = @getHomeCity().placemark.geometry.getPixelGeometry().getCoordinates()
        @draw.find('*').remove()
        for city in @getAvailableCities()
            to_p = city.placemark.geometry.getPixelGeometry().getCoordinates()
            @draw.path("M #{from_p[0] } #{ from_p[1] } L #{ to_p[0] } #{ to_p[1] }").stroke width: 1.5, color: 'black'



    getBoundsOfCitiesList: (cities_list) ->
        coords_list = cities_list.map (city) -> city.placemark.geometry.getCoordinates()
        coords_list.reduce (bnd, coords) ->
            bnd[0][0] = Math.min bnd[0][0], coords[0]
            bnd[0][1] = Math.min bnd[0][1], coords[1]
            bnd[1][0] = Math.max bnd[1][0], coords[0]
            bnd[1][1] = Math.max bnd[1][1], coords[1]
            bnd
        , [[Infinity,Infinity],[-Infinity,-Infinity]]

    setPreferredDestination: (destination_name_or_id) ->
        console.log "+++ setPreferredDestination: %o", destination_name_or_id
        home_city = @getHomeCity()
        @setStateForCity city for city in @getAvailableCities()
        preferred_destination_available_in_homecity = home_city.availableDestinations.find (d) -> d.Name == destination_name_or_id or d.Id == destination_name_or_id
        cities2check = @cities.filter (city, idx) => idx != 0 and city.distanceFromHome < @options.acceptableDistance or city.eeID == 2671
        await Promise.all cities2check.map (city) ->
            if city.availableDestinations
                return Promise.resolve()
            else
                return new Promise (resolve) ->
                    $fetchAvailableDestinationsFromID(city.eeID).then (ad) -> city.availableDestinations = ad; resolve()
        cities_with_preferred_destination_available = cities2check.filter (city) ->
            city.availableDestinations.find (d) -> d.Name == destination_name_or_id or d.Id == destination_name_or_id
        @setStateForCity city, 'available' for city in cities_with_preferred_destination_available

        clist = cities_with_preferred_destination_available.concat home_city
        coords = clist.map (c) -> c.placemark.geometry.getCoordinates()
        bounds = ymaps.util.bounds.fromPoints coords, @projection
        console.log bounds

        @ymap.setBounds bounds, duration: 500, checkZoomRange: yes
        setTimeout (=> @drawRoutes()), 501





