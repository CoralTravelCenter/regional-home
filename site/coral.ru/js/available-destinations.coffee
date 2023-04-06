import { responsiveHandler, observeElementProp } from '/site/common/js/utils.coffee'
import { $get } from './local-proxy.coffee'

isPreferredDestinationAvailable = (list, prefer) ->
    prefer ||= $('.data-column.destination-to').closest('[data-preferred-destination]').attr('data-preferred-destination')
    list.find (item) -> item.Name == prefer

export updateSelectionWithOrigin = (origin_name) ->
    $origin_item = $ $('.data-column.depart-from .item').toArray().find (item) -> $(item).text() == origin_name
    selectOriginItem $origin_item, 'dont-fallback'

export $fetchAvailableDestinationsFromID = (area_id) ->
    ajaxGet('/v1/geography/tocountryfilter', areaid: area_id)

export pagePreferredDestination = () ->
    selected_in_widget = $('.data-column.destination-to').closest('[data-preferred-destination]').attr('data-preferred-destination')
    selected_in_search_field = Number $('.packageSearch__destinationInput').attr 'countryid'
    selected_in_search_field || selected_in_widget

selectOriginItem = ($item, dont_fallback_to_moscow) ->
    $item = $($item)
    $item.siblings().removeClass 'selected'
    $fetchAvailableDestinationsFromID $item.attr('data-departureid')
    .then (response) ->
        if isPreferredDestinationAvailable response
            if dont_fallback_to_moscow
                $item.addClass('selected')
            else
                $item.addClass('selected')
            rebuildDestinationsListWithData response
        else
            if dont_fallback_to_moscow
                $item.addClass('selected')
                rebuildDestinationsListWithData response
            else
                setTimeout ->
                    selectOriginItem $('.data-column.depart-from .item[data-departureid="2671"]')
                ,0
        $item.closest('.scrollable').scrollTo $item, 500, offset: -30, complete: -> $item.addClass('selected')
    updateSelectionInfo()

export selectDestinationItem = ($item, dont_scroll) ->
    rebuildAirportsListWithData []
    $item = $($item)
    $item.siblings().removeClass 'selected'
    if dont_scroll
        $item.addClass('selected')
    else
        $item.closest('.scrollable').scrollTo $item, 500, offset: -30, complete: -> $item.addClass('selected')
    req_params =
        fromAreaId: $('.data-column.depart-from .item.selected').attr('data-departureid')
        toCountryId: $item.attr('data-id')
    ajaxGet '/v1/flight/availabledate', req_params
    .then (response) ->
        rebuildAirportsListWithData response.Result
    updateSelectionInfo()

export selectAirportListItem = ($item, dont_scroll) ->
    $item = $($item)
    $item.siblings().removeClass 'selected'
    if dont_scroll
        $item.addClass('selected')
    else
        $item.closest('.scrollable').scrollTo $item, 500, offset: -30, complete: -> $item.addClass('selected')
    updateSelectionInfo()

rebuildDestinationsListWithData = (list) ->
    $('.data-column.destination-airport-closest-date .scrollable').empty()
    $block = $('.data-column.destination-to')
    $container = $block.find('.scrollable')
    $container.empty()
    $container.append list.map (item_data) -> "<div class='item' data-id='#{ item_data.Id }'>#{ item_data.Name }</div>"
    $container.get(0).perfectscrollbar?.update()
    prefer = $block.closest('[data-preferred-destination]').attr('data-preferred-destination')
    preferred_item = $container.find('.item').toArray().find (item) -> $(item).text() == prefer
    selectDestinationItem preferred_item if preferred_item

rebuildAirportsListWithData = (list) ->
    $container = $('.data-column.destination-airport-closest-date .scrollable')
    $container.empty()
    items = list.map (item_data) -> "<div class='item dbl' data-toareaid='#{ item_data.ToAreaId }' data-flight-timestamp='#{ item_data.FlightDate.replace(/\D/g, '') }'><span>#{ item_data.ToAreaName }</span><span>#{ moment(Number(item_data.FlightDate.replace(/\D/g, ''))).format('DD.MM.YYYY') }</span></div>"
    $container.append items
    $container.get(0).perfectscrollbar?.update()
    if items.length == 1
        selectAirportListItem $container.find('.item'), 'dont-scroll'

updateSelectionInfo = ($ctx = '.available-flight-widget') ->
    $ctx = $($ctx)
    setTimeout ->
        $button = $('.foot [data-action="select-tour"]')
        $container = $ctx.find('.foot .selection-info').empty()
        items = $ctx.find('.data-column .item.selected').toArray().map (item) ->
            $item = $(item)
            if $item.children().length
                return "<span>#{ $item.children().map((idx, el) -> $(el).text()).toArray().join(', ') }</span>"
            else
                return "<span>#{ $item.text() }</span>"
        items_html = items.join('')
        $container.append items_html
        if items.length == 3
            $button.removeAttr 'disabled'
        else
            $button.attr disabled: 'disabled'
    , 1000

fetchDestinationWithFallback = (primary_id, fallback_id) ->
    $promise = $.Deferred()
    $.get '/v1/destination/destinationbyid', destinationId: primary_id
        .done (destination_response) ->
            destination = destination_response.Item
            if destination
                $promise.resolve(destination)
            else
                $.get '/v1/destination/destinationbyid', destinationId: fallback_id
                    .done (destination_response) ->
                        destination = destination_response.Item
                        $promise.resolve(destination)
    $promise

LOCAL_GET_CACHE = {}
ajaxGet = (endpoint, req_params) ->
    $promise = $.Deferred()
    request_uri = endpoint + '?' + $.param(req_params)
    if LOCAL_GET_CACHE[request_uri]
        $promise.resolve(if typeof LOCAL_GET_CACHE[request_uri] == 'string' then JSON.parse(LOCAL_GET_CACHE[request_uri]) else LOCAL_GET_CACHE[request_uri])
    else
        if window.location.hostname == 'localhost'
            $get(request_uri).then (response) -> $promise.resolve(response)
        else
            $.ajax(request_uri).then (response) ->
                LOCAL_GET_CACHE[request_uri] = response
                $promise.resolve(response)
    $promise
