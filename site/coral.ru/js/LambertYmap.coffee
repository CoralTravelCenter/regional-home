#import { AppState } from './app-state.js'

import { defineLambertProjection } from './define-lambert-projection.js'

export class LambertYmap
    constructor: (options) ->
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?apikey=49de5080-fb39-46f1-924b-dee5ddbad2f1&lang=ru-RU'
            appState: null
            worldFill: '#EAF3FB'
            genericFill: '#B6D7E3'
            genericStroke: '#FFFFFF'
            homeRegionFill: '#1EBDFF'
#            homeRegionFill: '#0093D0'
            options...
        }
        @bordersLoaded = new Promise (resolve) => @bordersLoadedResolve = resolve
    init: () ->
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
        $(document).on 'keyup keydown', (e) =>
            if [18].indexOf(e.which) >= 0
                @zoom_modifier_down = e.type == 'keydown'
        @options.appState && $(@options.appState).on 'changed', => @selectionChanged()
        @

    ymapsInit: () ->
        console.log '*** ymapsInit'

        LAMBERT_PROJECTION = await defineLambertProjection()

        window.ymap = @ymap = new ymaps.Map @$ymap.get(0),
            center:   [60, 100],
            zoom:     2,
            type:     null,
            controls: ['zoomControl']
        ,
            minZoom: 1,
            projection: new LAMBERT_PROJECTION()
        @ymap.controls.get('zoomControl').options.set size: 'small'

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

    findRegionByCity: (city) ->
        @regions.toArray().find (region) -> region.geometry.contains city.latlng

    setHomeCity: (city) ->
        city_placemark = new ymaps.Placemark city.latlng
        @ymap.geoObjects.add city_placemark
        home_region = @findRegionByCity city
        home_region.options.set 'fillColor', @options.homeRegionFill

