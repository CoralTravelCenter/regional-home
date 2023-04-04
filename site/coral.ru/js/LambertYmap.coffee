#import { AppState } from './app-state.js'

import { defineLambertProjection } from './define-lambert-projection.js'

export class LambertYmap
    constructor: (options) ->
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?apikey=49de5080-fb39-46f1-924b-dee5ddbad2f1&lang=ru-RU'
            appState: null
            options...
        }
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
        # what for wheel zoom modifier key (Alt)
        $(document).on 'keyup keydown', (e) =>
            if [18].indexOf(e.which) >= 0
                @zoom_modifier_down = e.type == 'keydown'
        @options.appState && $(@options.appState).on 'changed', => @selectionChanged()
        @

    ymapsInit: () ->
        console.log '*** ymapsInit'

        defineLambertProjection(ymaps)
        LAMBERT_PROJECTION = new ymaps.projection.LambertConformalConic();

        @ymap = new ymaps.Map @$ymap.get(0),
            center:   [60, 100],
            zoom:     1,
            type:     null,
            controls: ['zoomControl']
        ,
            minZoom: 1,
            projection: LAMBERT_PROJECTION
        @ymap.controls.get('zoomControl').options.set size: 'small'


        @$scrollZoomHint = $('.scrollzoom-hint')
        @scrollZoomTimeout = 0
        @scrollZoomUsed = false
        @ymap.events.add 'wheel', (e) =>
            if @zoom_modifier_down
                @$scrollZoomHint.removeClass 'shown'
                @scrollZoomUsed = true
            else
                e.preventDefault()
                unless @scrollZoomUsed
                    @$scrollZoomHint.addClass 'shown'
                    clearTimeout @scrollZoomTimeout
                    @scrollZoomTimeout = setTimeout () =>
                        @$scrollZoomHint.removeClass 'shown'
                    , 1000

