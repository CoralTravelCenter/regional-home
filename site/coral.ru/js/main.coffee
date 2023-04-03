import { fixLayout, autoplayVimeo, ASAP, preload, responsiveHandler, observeElementProp } from '/site/common/js/utils.coffee'
import { $fetchAndBuildBestDeals, selectDestinationTab } from './burning-tours.coffee'
import { updateSelectionWithOrigin } from './available-destinations.coffee'
import { getActiveDeparture } from './local-proxy.coffee'

Number::formatPrice = () ->
    s = String(Math.round(this))
    s.split('').reverse().join('').replace(/\d{3}/g, "$& ").split('').reverse().join('').replace(/^\s+/, '')


fixLayout()
autoplayVimeo()

doHover = () ->
    $this = $(this)
    idx = $this.index()
    $this.addClass('hovered').siblings('.hovered').removeClass('hovered')
    $('.intro .visual').eq(idx).addClass('shown').siblings().removeClass('shown')

ASAP ->
    do ->
        do_auto_play = yes
        $navs = $('.intro .eternal-package-search > *')
        intro_autoplay_interval = setInterval =>
            if do_auto_play
                idx = $('.intro .eternal-package-search > .hovered').index()
                idx = 0 if ++idx >= $navs.length
                doHover.apply $navs.eq(idx)
        , 2500
        $(document)
        .on 'mouseenter', '.intro .eternal-package-search > *', (e) =>
            do_auto_play = no
            doHover.apply e.target
        .on 'mouseleave', '.intro .eternal-package-search > *', (e) => do_auto_play = yes

    $flickityReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()

    $scrolltoReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.3/jquery.scrollTo.min.js', -> $scrolltoReady.resolve()
    $.when($scrolltoReady).done ->
        $(document).on 'click', '[data-scrollto]', -> $(window).scrollTo $(this).attr('data-scrollto'), 500, offset: -150
        $('.tabs-container .scroll-left').on 'click', ->
            $scroll_this = $('.burning-offers .tabs-selector')
            $scroll_this.scrollTo $scroll_this.children(':first'), 500
        $('.tabs-container .scroll-right').on 'click', ->
            $scroll_this = $('.burning-offers .tabs-selector')
            $scroll_this.scrollTo $scroll_this.children(':last'), 500


    $.when($fetchAndBuildBestDeals(preferred_destination_order)).done (available_destinations) ->
        $tabs_selector = $('.burning-offers .tabs-selector')
        $tabs_container = $tabs_selector.closest('.tabs-container')
        lis_html = available_destinations.map (d) ->
            "<li data-destination-name='#{ d.destination_name }' data-destination-id='#{ d.destination_id }' data-destination-url='#{ d.destination_url }' data-option-id='#{ d.option_id }'>#{ d.destination_name }</li>"
        .join ''
        $tabs_selector.empty().append lis_html

        first_tab_el = $tabs_selector.children(':first').get(0)
        last_tab_el = $tabs_selector.children(':last').get(0)
        io = new IntersectionObserver (entries, observer) ->
            for entry in entries
                if entry.target == first_tab_el
                    $tabs_container.toggleClass 'scrollable-left', not entry.isIntersecting
                else if entry.target == last_tab_el
                    $tabs_container.toggleClass 'scrollable-right', not entry.isIntersecting
        , threshold: 0.5, root: $tabs_container.get(0)
        io.observe first_tab_el
        io.observe last_tab_el

        selectDestinationTab '.burning-offers [data-destination-name]:first', $flickityReady

        $(document).on 'click', '.burning-offers [data-destination-name]', ->
            selectDestinationTab this, $flickityReady
            $('.flickity-enabled').flickity 'resize'

    $.when($flickityReady).done ->
        $('.hot-slider').flickity
            cellSelector: '.hot-slide'
            cellAlign: 'center'
            wrapAround: yes
            prevNextButtons: yes
            pageDots: yes

    $(document).on 'wheel', '.flickity-enabled', _.debounce (e) ->
        e.stopPropagation()
        if e.originalEvent.deltaX > 0
            $(this).flickity('next')
        else if e.originalEvent.deltaX < 0
            $(this).flickity('previous')
    , 40, leading: yes, trailing: no

    # Available destinations module/block
    $available_flight_widget = $('.available-flight-widget')
    responsiveHandler '(max-width: 768px)',
        ->
            $headitems = $('.head-item', $available_flight_widget)
            $('.data-column', $available_flight_widget).each (idx, el) ->
                $(el).prepend $headitems.eq(idx)
            $('.data-column .scrollable').each (idx, el) ->
                el.perfectscrollbar?.update()
        ->
            $('.head', $available_flight_widget).append($('.head-item', $available_flight_widget))
            $('.data-column .scrollable').each (idx, el) ->
                el.perfectscrollbar?.update()

    nodes_array = $('.geolocation-list li').map (idx, li) ->
        $li = $(li)
        $('<div class="item"></div>').text($li.text()).attr('data-departureid': $li.attr('data-departureid')).get(0)
    $('.data-column.depart-from .scrollable').empty().append nodes_array

    libs = [
        'https://cdnjs.cloudflare.com/ajax/libs/jquery.perfect-scrollbar/1.5.5/perfect-scrollbar.min.js',
    ]
    $libsReady = $.Deferred()
    preload libs, -> $libsReady.resolve()

    unless window.location.hostname == 'localhost'
        observeElementProp $('input.packageSearch__departureInput').get(0), 'value', (new_origin) ->
            updateSelectionWithOrigin new_origin if new_origin

    $.when($libsReady, $scrolltoReady).done ->
        $('.scrollable', $available_flight_widget).each (idx, el) ->
            el.perfectscrollbar = new PerfectScrollbar(el, { minScrollbarLength: 20, wheelPropagation: false })
        updateSelectionWithOrigin getActiveDeparture()?.name

        $(document).on 'click', '.data-column.depart-from .item', (e) ->
            selectOriginItem this, 'dont_fallback'

        $(document).on 'click', '.data-column.destination-to .item', (e) ->
            $this = $(this)
            $this.closest('.data-column').attr 'data-preferred-destination', $this.text()
            selectDestinationItem $this, 'dont-scroll'

        $(document).on 'click', '.data-column.destination-airport-closest-date .item', (e) ->
            $this = $(this)
            selectAirportListItem $this, 'dont-scroll'

        $('[data-action="select-tour"]').on 'click', (e) ->
            window.global.travelloader.show()
            $departure_item = $('.data-column.depart-from .item.selected')
            fromAreaId = $departure_item.attr 'data-departureid'
            fromAreaLabel = $departure_item.text()
            destinationCountryId = $('.data-column.destination-to .item.selected').attr 'data-id'
            $airport_item = $('.data-column.destination-airport-closest-date .item.selected')
            to_area_id = $airport_item.attr 'data-toareaid'
            flight_moment = moment(Number($airport_item.attr('data-flight-timestamp')))
            fetchDestinationWithFallback to_area_id, "Country#{ destinationCountryId }"
                .done (destination_response) ->
                    destination = destination_response
                    $.ajax '/v1/flight/availablenights',
                        data:
                            fromAreaId:      fromAreaId
                            destinationId:   destination.Id
                            toCountryId:     destinationCountryId
                            toAreaId:        ''
                            toPlaceId:       ''
                            nearestAirports: destination.NearestAirports.join(',')
                            beginDate:       flight_moment.format('YYYY-MM-DD')
                            endDate:         flight_moment.format('YYYY-MM-DD')
                            flightType:      ''
                    .then (available_nights_response) ->
                        if available_nights_response.Result.length
                            nights = available_nights_response.Result.slice().filter (n) -> n != 1
                            .sort (a, b) ->
                                va = Math.abs(7 - a)
                                vb = Math.abs(7 - b)
                                if va < vb then -1 else (if va > vb then 1 else 0)
                            .slice(0, 3).sort (a, b) -> a - b
                            $.ajax '/v1/package/search',
                                method: 'post'
                                data:
                                    isCharter:    true,
                                    isRegular:    true
                                    Guest:        Adults: 2
                                    SelectedDate: flight_moment.format('YYYY-MM-DD')
                                    DateRange:    0,
                                    BeginDate:    flight_moment.format('YYYY-MM-DD')
                                    EndDate:      flight_moment.format('YYYY-MM-DD')
                                    Acc:          nights,
                                    Departures:   [{ Id: fromAreaId, Label: fromAreaLabel }],
                                    Destination:  [destination]
                            .then (package_search_response) ->
                                location.href = package_search_response
                        else
                            alert 'Нет вариантов размещения'
                            window.global.travelloader.hide()
